import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/shiny_hunt.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/shiny_hunt_provider.dart';
import '../../../services/desktop_tracker/desktop_tracker_service.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/mobile_scanner/mobile_camera_tracker_service.dart';
import '../../../services/scanner_core/models/scanner_event.dart';
import '../../../services/scanner_core/models/scanner_settings.dart';
import '../../../services/scanner_core/scanner_coordinator.dart';
import '../../../services/scanner_core/scanner_launcher_helper.dart';
import '../../../services/scanner_core/source/scanner_source.dart';
import '../../../services/shiny_auto_counter/shiny_auto_counter_config.dart';
import '../../../services/shiny_auto_counter/shiny_auto_counter_service.dart';
import '../../../utils/tracker_platform_helper.dart';
import '../controllers/shiny_auto_counter_setup_tutorial_controller.dart';

/// Bottom sheet / modal for configuring and launching the visual Shiny-Hunt auto-counter.
class ShinyAutoCounterSetupSheet extends StatefulWidget {
  final ShinyHunt hunt;
  final ShinyAutoCounterService? service;
  final VoidCallback? onStarted;
  final bool showSourceLauncher;
  final bool perHuntOverride;
  final bool preserveDefaultHuntId;
  final bool scrollable;
  final BuildContext? parentContext;

  const ShinyAutoCounterSetupSheet({
    super.key,
    required this.hunt,
    this.service,
    this.onStarted,
    this.showSourceLauncher = true,
    this.perHuntOverride = false,
    this.preserveDefaultHuntId = false,
    this.scrollable = true,
    this.parentContext,
  });

  static Future<void> show(
    BuildContext context, {
    required ShinyHunt hunt,
    ShinyAutoCounterService? service,
    VoidCallback? onStarted,
    bool perHuntOverride = false,
    bool preserveDefaultHuntId = false,
  }) {
    final parentContext = context;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: ShinyAutoCounterSetupSheet(
            hunt: hunt,
            service: service,
            onStarted: onStarted,
            perHuntOverride: perHuntOverride,
            preserveDefaultHuntId: preserveDefaultHuntId,
            scrollable: false,
            parentContext: parentContext,
          ),
        ),
      ),
    );
  }

  @override
  State<ShinyAutoCounterSetupSheet> createState() =>
      _ShinyAutoCounterSetupSheetState();
}

class _ShinyAutoCounterSetupSheetState
    extends State<ShinyAutoCounterSetupSheet> {
  late ShinyAutoCounterSettings _settings;
  bool _userEdited = false;
  final TextEditingController _triggerController = TextEditingController();
  final TextEditingController _resetController = TextEditingController();
  late final TextEditingController _cooldownController;
  late final TextEditingController _transitionDurationController;
  final ShinyAutoCounterSetupTutorialController _tutorialController =
      ShinyAutoCounterSetupTutorialController();

  ShinyAutoCounterService get _service =>
      widget.service ?? ShinyAutoCounterService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.perHuntOverride) {
      _settings = _service.settingsForHunt(widget.hunt);
    } else {
      _settings = _service.isRunning
          ? _service.settings
          : ShinyAutoCounterSettings.forHuntMethod(widget.hunt.method);
    }
    _cooldownController = TextEditingController(
      text: _settings.minResetCooldownMs.toString(),
    );
    _transitionDurationController = TextEditingController(
      text: _settings.transitionMinDurationMs.toString(),
    );

    unawaited(_loadPersistedSettings());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tutorialController.showIfNeeded(
        context: context,
        isMounted: mounted,
        perHuntOverride: widget.perHuntOverride,
      );
    });
  }

  Future<void> _loadPersistedSettings() async {
    await _service.ensureSettingsLoaded();
    final saved = await ShinyAutoCounterSettings.loadFromPrefs();
    if (!mounted || _service.isRunning || _userEdited) {
      return;
    }
    if (widget.perHuntOverride) {
      final resolved = _service.settingsForHunt(widget.hunt);
      setState(() {
        _settings = resolved;
        _syncTimingControllers();
      });
      return;
    }
    if (saved != null) {
      setState(() {
        _settings = saved;
        _syncTimingControllers();
      });
    }
  }

  void _syncTimingControllers() {
    _cooldownController.text = _settings.minResetCooldownMs.toString();
    _transitionDurationController.text =
        _settings.transitionMinDurationMs.toString();
  }

  @override
  void dispose() {
    _triggerController.dispose();
    _resetController.dispose();
    _cooldownController.dispose();
    _transitionDurationController.dispose();
    super.dispose();
  }

  ({
    ScannerCoordinator? coordinator,
    ScannerSource? source,
    List<int> slotIds,
    Map<int, int> slotColors,
  }) _resolveActiveSource() {
    final desktop = DesktopTrackerService.instance;
    if (desktop.coordinator != null && desktop.isTrackingActive) {
      final isCam = desktop.activeWindow?.isCameraSource == true &&
          desktop.activeSource != null &&
          !identical(desktop.activeSource, desktop.windowSource);
      final slots = isCam
          ? const <MultiInstanceSlot>[]
          : (desktop.windowSource?.multiInstanceSlots
                  .where((s) => s.enabled)
                  .toList() ??
              const <MultiInstanceSlot>[]);
      final slotIds =
          slots.isNotEmpty ? slots.map((s) => s.id).toList() : <int>[1];
      final slotColors = {
        for (final s in slots) s.id: s.colorHex,
      };
      return (
        coordinator: desktop.coordinator,
        source: desktop.activeSource,
        slotIds: slotIds,
        slotColors: slotColors,
      );
    }

    final mobile = MobileCameraTrackerService.instance;
    if (mobile.coordinator != null && mobile.isTrackingActive) {
      final multiRegions = mobile.regions
          .where((r) => r.enabled && r.slotId != null)
          .toList();
      final hasPrimaryScan = mobile.scanMode == MobileCameraScanMode.autoFull ||
          mobile.regions.any(
            (r) => r.enabled && r.role == CameraZoneRole.scan && r.slotId == null,
          );
      final slotIdSet = <int>{
        if (hasPrimaryScan || multiRegions.isEmpty) 1,
        ...multiRegions.map((r) => r.slotId!),
      };
      final slotIds = slotIdSet.toList()..sort();
      final slotColors = {
        for (final r in multiRegions) r.slotId!: r.colorHex,
      };
      return (
        coordinator: mobile.coordinator,
        source: mobile.cameraSource,
        slotIds: slotIds,
        slotColors: slotColors,
      );
    }

    return (
      coordinator: _service.coordinator,
      source: _service.source,
      slotIds: const [1],
      slotColors: const {},
    );
  }

  void _updateSettings(ShinyAutoCounterSettings next) {
    setState(() {
      _userEdited = true;
      _settings = next;
    });
  }

  void _commitCooldownText(String raw, {bool clampAndSync = true}) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      if (clampAndSync) {
        _cooldownController.text = _settings.minResetCooldownMs.toString();
      }
      return;
    }
    if (!clampAndSync && parsed < 200) return;
    final clamped = parsed.clamp(200, 30000);
    if (clamped != _settings.minResetCooldownMs) {
      _updateSettings(_settings.copyWith(minResetCooldownMs: clamped));
    }
    if (clampAndSync) {
      _cooldownController.text = clamped.toString();
    }
  }

  void _commitTransitionText(String raw, {bool clampAndSync = true}) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      if (clampAndSync) {
        _transitionDurationController.text =
            _settings.transitionMinDurationMs.toString();
      }
      return;
    }
    if (!clampAndSync && parsed < 150) return;
    final clamped = parsed.clamp(150, 5000);
    if (clamped != _settings.transitionMinDurationMs) {
      _updateSettings(_settings.copyWith(transitionMinDurationMs: clamped));
    }
    if (clampAndSync) {
      _transitionDurationController.text = clamped.toString();
    }
  }

  void _addCustomTrigger() {
    final text = _triggerController.text.trim();
    if (text.isEmpty) return;
    final next = List<CustomOcrPattern>.from(_settings.customTriggerPatterns)
      ..add(
        CustomOcrPattern(
          id: 'shiny_trig_${DateTime.now().microsecondsSinceEpoch}',
          template: text,
          eventType: _settings.detectionMode == ShinyHuntDetectionMode.eggHatch
              ? ScannerEventType.eggHatched
              : ScannerEventType.encounter,
        ),
      );
    _triggerController.clear();
    _updateSettings(_settings.copyWith(customTriggerPatterns: next));
  }

  void _addCustomReset() {
    final text = _resetController.text.trim();
    if (text.isEmpty) return;
    final next = List<String>.from(_settings.customResetPatterns)..add(text);
    _resetController.clear();
    _updateSettings(_settings.copyWith(customResetPatterns: next));
  }

  Future<void> _applyOrStart() async {
    _commitCooldownText(_cooldownController.text);
    _commitTransitionText(_transitionDurationController.text);
    if (_triggerController.text.trim().isNotEmpty) {
      _addCustomTrigger();
    }
    if (_resetController.text.trim().isNotEmpty) {
      _addCustomReset();
    }

    if (widget.perHuntOverride) {
      await _service.ensureSettingsLoaded();
      if (!mounted) return;
      _service.updateHuntSettings(widget.hunt.id, _settings);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    await _service.ensureSettingsLoaded();
    if (!mounted) return;

    final effectiveSettings = _settings.copyWith(
      slotToHuntOverrides: {
        ..._service.settings.slotToHuntOverrides,
        ..._settings.slotToHuntOverrides,
      },
      huntSettingsOverrides: {
        ..._service.settings.huntSettingsOverrides,
        ..._settings.huntSettingsOverrides,
      },
    );
    _settings = effectiveSettings;

    await ShinyAutoCounterSettings.saveToPrefs(effectiveSettings);
    if (!mounted) return;

    final active = _resolveActiveSource();
    final huntProvider =
        Provider.of<ShinyHuntProvider>(context, listen: false);

    if (_service.isRunning &&
        (active.coordinator == null ||
            identical(_service.coordinator, active.coordinator))) {
      _service.updateSettings(effectiveSettings);
      if (!widget.preserveDefaultHuntId &&
          _service.defaultHuntId != widget.hunt.id) {
        _service.setDefaultHuntId(widget.hunt.id);
      }
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (active.coordinator != null) {
      _service.startSession(
        huntProvider: huntProvider,
        coordinator: active.coordinator!,
        source: active.source,
        defaultHuntId: widget.hunt.id,
        slotIds: active.slotIds,
        slotColorOverrides: active.slotColors,
        settings: effectiveSettings,
      );
      widget.onStarted?.call();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    // No active source yet -> arm pending auto-connect and open platform scanner setup
    if (widget.showSourceLauncher) {
      final dexProvider = Provider.of<DexProvider>(context, listen: false);
      final navigator = Navigator.of(context);
      final launchContext = widget.parentContext ?? navigator.context;
      _service.armPendingSession(
        huntProvider: huntProvider,
        defaultHuntId: widget.hunt.id,
        settings: effectiveSettings,
      );
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }
      if (launchContext.mounted) {
        ScannerLauncherHelper.openPlatformTracker(
          launchContext,
          allPokemon: dexProvider.allPokemon,
          dexId: widget.hunt.targetDexId,
        );
      }
    }
  }

  String _modeLabel(ShinyHuntDetectionMode mode) {
    return switch (mode) {
      ShinyHuntDetectionMode.wildEncounter => t.shiny_auto_mode_wild,
      ShinyHuntDetectionMode.softReset => t.shiny_auto_mode_soft_reset,
      ShinyHuntDetectionMode.eggHatch => t.shiny_auto_mode_egg,
      ShinyHuntDetectionMode.screenTransitionOnly =>
        t.shiny_auto_mode_transition,
    };
  }

  String _modeDescription(ShinyHuntDetectionMode mode) {
    return switch (mode) {
      ShinyHuntDetectionMode.wildEncounter => t.shiny_auto_mode_desc_wild,
      ShinyHuntDetectionMode.softReset => t.shiny_auto_mode_desc_soft_reset,
      ShinyHuntDetectionMode.eggHatch => t.shiny_auto_mode_desc_egg,
      ShinyHuntDetectionMode.screenTransitionOnly =>
        t.shiny_auto_mode_desc_transition,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTransitionOnly =
        _settings.detectionMode == ShinyHuntDetectionMode.screenTransitionOnly;
    final isWildMode =
        _settings.detectionMode == ShinyHuntDetectionMode.wildEncounter;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _service.isRunningNotifier,
        DesktopTrackerService.instance.isTrackingNotifier,
        MobileCameraTrackerService.instance.isTrackingNotifier,
      ]),
      builder: (context, _) {
        final active = _resolveActiveSource();
        final hasActiveSource = active.coordinator != null;

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.center_focus_strong, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.perHuntOverride
                        ? t.shiny_auto_setup_for_hunt.replaceAll(
                            '{name}',
                            widget.hunt.title.isNotEmpty
                                ? widget.hunt.title
                                : widget.hunt.pokemonName,
                          )
                        : t.shiny_auto_setup_title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Source status & launcher (hidden for per-hunt rule modal)
            if (!widget.perHuntOverride)
              Column(
                key: _tutorialController.sourceSectionKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.shiny_auto_source_section,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasActiveSource
                                  ? Icons.check_circle
                                  : Icons.sensors_off,
                              size: 18,
                              color:
                                  hasActiveSource ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasActiveSource
                                    ? '${t.shiny_auto_source_connected} (${active.slotIds.length}×)'
                                    : t.shiny_auto_source_none,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (widget.showSourceLauncher) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: Icon(
                              TrackerPlatformHelper.isMobile
                                  ? Icons.camera_alt_outlined
                                  : Icons.desktop_windows_outlined,
                              size: 16,
                            ),
                            label: Text(
                              TrackerPlatformHelper.isMobile
                                  ? t.shiny_auto_open_mobile_scanner
                                  : t.shiny_auto_open_desktop_scanner,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              final dexProvider = Provider.of<DexProvider>(
                                context,
                                listen: false,
                              );
                              ScannerLauncherHelper.openPlatformTracker(
                                context,
                                allPokemon: dexProvider.allPokemon,
                                dexId: widget.hunt.targetDexId,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),

            // 2. Detection Mode Preset
            Column(
              key: _tutorialController.modeSectionKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.shiny_auto_mode_section,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ShinyHuntDetectionMode.values.map((mode) {
                    final selected = _settings.detectionMode == mode;
                    return ChoiceChip(
                      key: Key('setup_mode_${mode.name}'),
                      label: Text(_modeLabel(mode),
                          style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) {
                        final targetEventType =
                            mode == ShinyHuntDetectionMode.eggHatch
                                ? ScannerEventType.eggHatched
                                : ScannerEventType.encounter;
                        final updatedTriggers = _settings.customTriggerPatterns
                            .map(
                              (p) => CustomOcrPattern(
                                id: p.id,
                                template: p.template,
                                eventType: targetEventType,
                                enabled: p.enabled,
                              ),
                            )
                            .toList();
                        _updateSettings(
                          _settings.copyWith(
                            detectionMode: mode,
                            matchFilter: mode.defaultMatchFilter,
                            customTriggerPatterns: updatedTriggers,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Container(
                  key: const Key('setup_mode_info_box'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _modeDescription(_settings.detectionMode),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_settings.detectionMode ==
                    ShinyHuntDetectionMode.softReset) ...[
                  const SizedBox(height: 6),
                  Text(
                    t.shiny_auto_soft_reset_starter_hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),

            // 3. Match filter & transition toggles
            Column(
              key: _tutorialController.filterResetSectionKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isTransitionOnly) ...[
                  Text(
                    t.shiny_auto_filter_section,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        key: Key(
                          'setup_filter_${ShinyMatchFilter.allPokemon.name}',
                        ),
                        label: Text(t.shiny_auto_filter_all,
                            style: const TextStyle(fontSize: 12)),
                        selected:
                            _settings.matchFilter == ShinyMatchFilter.allPokemon,
                        onSelected: (_) => _updateSettings(
                          _settings.copyWith(
                            matchFilter: ShinyMatchFilter.allPokemon,
                          ),
                        ),
                      ),
                      ChoiceChip(
                        key: Key(
                          'setup_filter_${ShinyMatchFilter.targetPokemonOnly.name}',
                        ),
                        label: Text(t.shiny_auto_filter_target,
                            style: const TextStyle(fontSize: 12)),
                        selected: _settings.matchFilter ==
                            ShinyMatchFilter.targetPokemonOnly,
                        onSelected: (_) => _updateSettings(
                          _settings.copyWith(
                            matchFilter: ShinyMatchFilter.targetPokemonOnly,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _settings.matchFilter == ShinyMatchFilter.allPokemon
                        ? t.shiny_auto_filter_desc_all
                        : t.shiny_auto_filter_desc_target,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isWildMode)
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.shiny_auto_horde_toggle,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        t.shiny_auto_horde_desc,
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: _settings.useEventEncounterCount,
                      onChanged: (v) => _updateSettings(
                        _settings.copyWith(useEventEncounterCount: v),
                      ),
                    ),
                ],
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_black_reset_toggle,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    t.shiny_auto_black_reset_desc,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _settings.enableBlackScreenReset,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(enableBlackScreenReset: v),
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_white_reset_toggle,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    t.shiny_auto_white_reset_desc,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _settings.enableWhiteScreenReset,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(enableWhiteScreenReset: v),
                  ),
                ),
                if (isTransitionOnly &&
                    !_settings.enableBlackScreenReset &&
                    !_settings.enableWhiteScreenReset)
                  Container(
                    key: const Key('setup_transition_none_warning'),
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.shiny_auto_transition_none_warning,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),

            // 4. Custom Trigger & Reset Patterns
            Column(
              key: _tutorialController.customPatternsSectionKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isTransitionOnly) ...[
                  Text(
                    t.shiny_auto_custom_triggers,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.shiny_auto_custom_triggers_desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('setup_custom_trigger_field'),
                          controller: _triggerController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: t.shiny_auto_custom_trigger_hint,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addCustomTrigger(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        key: const Key('setup_add_trigger_btn'),
                        onPressed: _addCustomTrigger,
                        child: Text(t.shiny_auto_add_btn),
                      ),
                    ],
                  ),
                  if (_settings.customTriggerPatterns.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _settings.customTriggerPatterns.map((p) {
                          return InputChip(
                            label: Text(p.template,
                                style: const TextStyle(fontSize: 11)),
                            onDeleted: () {
                              _updateSettings(
                                _settings.copyWith(
                                  customTriggerPatterns: _settings
                                      .customTriggerPatterns
                                      .where((e) => e.id != p.id)
                                      .toList(),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],

                Text(
                  t.shiny_auto_custom_resets,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  t.shiny_auto_custom_resets_desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('setup_custom_reset_field'),
                        controller: _resetController,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: t.shiny_auto_custom_reset_hint,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addCustomReset(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      key: const Key('setup_add_reset_btn'),
                      onPressed: _addCustomReset,
                      child: Text(t.shiny_auto_add_btn),
                    ),
                  ],
                ),
                if (_settings.customResetPatterns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          _settings.customResetPatterns.asMap().entries.map((e) {
                        return InputChip(
                          label:
                              Text(e.value, style: const TextStyle(fontSize: 11)),
                          onDeleted: () {
                            final next = List<String>.from(
                              _settings.customResetPatterns,
                            )..removeAt(e.key);
                            _updateSettings(
                              _settings.copyWith(customResetPatterns: next),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),

            // 5. Advanced / Timing Tuning (Slider + Custom ms input + Luma Thresholds)
            KeyedSubtree(
              key: _tutorialController.timingSectionKey,
              child: ExpansionTile(
              key: const Key('setup_timing_expansion'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                t.shiny_auto_timing_section,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_settings.minResetCooldownMs} ms · ${_settings.transitionMinDurationMs} ms · Luma ${_settings.blackLumaThreshold}/${_settings.whiteLumaThreshold}',
                style: const TextStyle(fontSize: 11),
              ),
              children: [
                _TimingSliderRow(
                  label: t.shiny_auto_cooldown_label,
                  helperText: t.shiny_auto_cooldown_desc,
                  valueMs: _settings.minResetCooldownMs,
                  sliderMin: 200,
                  sliderMax: 5000,
                  divisions: 48,
                  controller: _cooldownController,
                  inputKey: const Key('setup_cooldown_input'),
                  onSliderChanged: (v) {
                    final ms = v.round();
                    _cooldownController.text = ms.toString();
                    _updateSettings(
                      _settings.copyWith(minResetCooldownMs: ms),
                    );
                  },
                  onTextChanged: (raw) =>
                      _commitCooldownText(raw, clampAndSync: false),
                  onTextCommitted: (raw) =>
                      _commitCooldownText(raw, clampAndSync: true),
                ),
                const SizedBox(height: 8),
                _TimingSliderRow(
                  label: t.shiny_auto_transition_duration_label,
                  helperText: t.shiny_auto_transition_duration_desc,
                  valueMs: _settings.transitionMinDurationMs,
                  sliderMin: 150,
                  sliderMax: 2000,
                  divisions: 37,
                  controller: _transitionDurationController,
                  inputKey: const Key('setup_transition_input'),
                  onSliderChanged: (v) {
                    final ms = v.round();
                    _transitionDurationController.text = ms.toString();
                    _updateSettings(
                      _settings.copyWith(transitionMinDurationMs: ms),
                    );
                  },
                  onTextChanged: (raw) =>
                      _commitTransitionText(raw, clampAndSync: false),
                  onTextCommitted: (raw) =>
                      _commitTransitionText(raw, clampAndSync: true),
                ),
                const SizedBox(height: 10),
                Text(
                  t.shiny_auto_black_threshold_label.replaceAll(
                    '{value}',
                    _settings.blackLumaThreshold.toString(),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                Slider(
                  key: const Key('setup_black_threshold_slider'),
                  value: _settings.blackLumaThreshold.toDouble().clamp(5, 80),
                  min: 5,
                  max: 80,
                  divisions: 15,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(blackLumaThreshold: v.round()),
                  ),
                ),
                Text(
                  t.shiny_auto_white_threshold_label.replaceAll(
                    '{value}',
                    _settings.whiteLumaThreshold.toString(),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                Slider(
                  key: const Key('setup_white_threshold_slider'),
                  value: _settings.whiteLumaThreshold.toDouble().clamp(175, 252),
                  min: 175,
                  max: 252,
                  divisions: 77,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(whiteLumaThreshold: v.round()),
                  ),
                ),
                Text(
                  t.shiny_auto_thresholds_desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(height: 8),

            // 6. Safety & Notifications
            Column(
              key: _tutorialController.safetyStartSectionKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.shiny_auto_safety_section,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  key: const Key('setup_toggle_sound_count'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_sound_count,
                      style: const TextStyle(fontSize: 13)),
                  value: _settings.playSoundOnCount,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(playSoundOnCount: v),
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_haptic_count,
                      style: const TextStyle(fontSize: 13)),
                  value: _settings.playHapticOnCount,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(playHapticOnCount: v),
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_sound_shiny,
                      style: const TextStyle(fontSize: 13)),
                  value: _settings.playSoundOnShiny,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(playSoundOnShiny: v),
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_haptic_shiny,
                      style: const TextStyle(fontSize: 13)),
                  value: _settings.playHapticOnShiny,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(playHapticOnShiny: v),
                  ),
                ),
                SwitchListTile(
                  key: const Key('setup_toggle_auto_pause_shiny'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_pause_on_shiny,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    t.shiny_auto_pause_on_shiny_desc,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _settings.autoPauseSlotOnShiny,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(autoPauseSlotOnShiny: v),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.shiny_auto_shiny_ocr_info,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  key: const Key('setup_toggle_sparkle_delay'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_sparkle_delay_toggle,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    t.shiny_auto_sparkle_delay_desc,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _settings.enableSparkleDelayShinyCheck,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(enableSparkleDelayShinyCheck: v),
                  ),
                ),
                if (_settings.enableSparkleDelayShinyCheck) ...[
                  Text(
                    t.shiny_auto_sparkle_delay_threshold_label.replaceAll(
                      '{ms}',
                      _settings.sparkleDelayThresholdMs.toString(),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Slider(
                    key: const Key('setup_sparkle_delay_slider'),
                    value: _settings.sparkleDelayThresholdMs
                        .toDouble()
                        .clamp(500, 3500),
                    min: 500,
                    max: 3500,
                    divisions: 30,
                    onChanged: (v) => _updateSettings(
                      _settings.copyWith(sparkleDelayThresholdMs: v.round()),
                    ),
                  ),
                ],
                SwitchListTile(
                  key: const Key('setup_toggle_color_deviation'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.shiny_auto_color_dev_toggle,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    t.shiny_auto_color_dev_desc,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _settings.enableColorDeviationShinyCheck,
                  onChanged: (v) => _updateSettings(
                    _settings.copyWith(enableColorDeviationShinyCheck: v),
                  ),
                ),
                if (_settings.enableColorDeviationShinyCheck) ...[
                  Text(
                    t.shiny_auto_color_dev_threshold_label.replaceAll(
                      '{pct}',
                      (_settings.colorDeviationThreshold * 100)
                          .round()
                          .toString(),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Slider(
                    key: const Key('setup_color_deviation_slider'),
                    value: (_settings.colorDeviationThreshold * 100)
                        .clamp(20, 70),
                    min: 20,
                    max: 70,
                    divisions: 25,
                    onChanged: (v) => _updateSettings(
                      _settings.copyWith(
                        colorDeviationThreshold: v.round() / 100.0,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                FilledButton.icon(
                  key: const Key('setup_start_btn'),
                  icon: Icon(
                    _service.isRunning
                        ? Icons.check_rounded
                        : (hasActiveSource
                            ? Icons.play_arrow_rounded
                            : Icons.sensors_rounded),
                  ),
                  label: Text(
                    widget.perHuntOverride || _service.isRunning
                        ? t.shiny_auto_save_btn
                        : (hasActiveSource
                            ? t.shiny_auto_connect_active_source
                            : t.shiny_auto_start_btn),
                  ),
                  onPressed: _applyOrStart,
                ),
              ],
            ),
          ],
        );

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: widget.scrollable
                ? SingleChildScrollView(child: content)
                : content,
          ),
        );
      },
    );
  }
}

class _TimingSliderRow extends StatelessWidget {
  final String label;
  final String? helperText;
  final int valueMs;
  final double sliderMin;
  final double sliderMax;
  final int divisions;
  final TextEditingController controller;
  final Key inputKey;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onTextCommitted;

  const _TimingSliderRow({
    required this.label,
    this.helperText,
    required this.valueMs,
    required this.sliderMin,
    required this.sliderMax,
    required this.divisions,
    required this.controller,
    required this.inputKey,
    required this.onSliderChanged,
    required this.onTextChanged,
    required this.onTextCommitted,
  });

  @override
  Widget build(BuildContext context) {
    final sliderValue = valueMs.toDouble().clamp(sliderMin, sliderMax);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        if (helperText != null) ...[
          const SizedBox(height: 2),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: Slider(
                value: sliderValue,
                min: sliderMin,
                max: sliderMax,
                divisions: divisions,
                onChanged: onSliderChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: TextField(
                key: inputKey,
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: 'ms',
                  border: OutlineInputBorder(),
                ),
                onChanged: onTextChanged,
                onSubmitted: onTextCommitted,
                onEditingComplete: () => onTextCommitted(controller.text),
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                  onTextCommitted(controller.text);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
