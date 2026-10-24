import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/shiny_hunt.dart';
import '../../models/tutorial_step.dart';
import '../../providers/dex_provider.dart';
import '../../providers/shiny_hunt_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../utils/shiny_hunt_odds_helper.dart';
import '../../utils/dex_logic_helper.dart';
import '../../l10n/app_translations.dart';
import '../../widgets/universal_poke_image.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import 'dialogs/create_edit_hunt_dialog.dart';
import 'dialogs/record_phase_dialog.dart';
import 'dialogs/shiny_catch_dialog.dart';
import 'dialogs/shiny_hunt_timeline_dialog.dart';

class ShinyHuntCounterScreen extends StatefulWidget {
  final String huntId;

  const ShinyHuntCounterScreen({super.key, required this.huntId});

  @override
  State<ShinyHuntCounterScreen> createState() => _ShinyHuntCounterScreenState();
}

class _ShinyHuntCounterScreenState extends State<ShinyHuntCounterScreen> {
  final FocusNode _keyboardFocusNode = FocusNode();
  ShinyHuntProvider? _huntProvider;

  bool _isLockMode = false;
  bool _showShinySprite = true;
  bool _hapticsEnabled = true;
  bool _wakelockEnabled = true;
  int? _customStep;

  final GlobalKey _counterAreaKey = GlobalKey();
  final GlobalKey _buttonsKey = GlobalKey();
  final GlobalKey _phasesActionsKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
        huntProvider.setActiveCounterHunt(widget.huntId);
        _applyWakelock();
        _showTutorialIfNeeded();
      }
    });
  }

  void _showTutorialIfNeeded() {
    final TutorialProvider tutProvider;
    try {
      tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    } catch (_) {
      return;
    }

    ShinyHuntProvider? huntProvider;
    try {
      huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
    } catch (_) {
      huntProvider = null;
    }
    final hunt = huntProvider?.getHuntById(widget.huntId);
    if (hunt == null || hunt.isCompleted) return;

    if (!tutProvider.hasSeenFeature('shiny_hunt_counter')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'shiny_hunt_counter',
          nameKey: 'tutorial_chapter_shiny_hunt_title',
          steps: [
            TutorialStep(
              targetKey: _counterAreaKey,
              titleKey: 'tutorial_shiny_counter_title',
              textKey: 'tutorial_shiny_counter_text',
              rotomMood: RotomMood.explaining,
            ),
            TutorialStep(
              targetKey: _buttonsKey,
              titleKey: 'tutorial_shiny_buttons_title',
              textKey: 'tutorial_shiny_buttons_text',
              rotomMood: RotomMood.thinking,
            ),
            TutorialStep(
              targetKey: _phasesActionsKey,
              titleKey: 'tutorial_shiny_phases_actions_title',
              textKey: 'tutorial_shiny_phases_actions_text',
              rotomMood: RotomMood.happy,
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('shiny_hunt_counter'),
      );
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _huntProvider?.setActiveCounterHunt(null);
    _huntProvider?.flushPendingWrites();
    if (_wakelockEnabled) {
      try {
        WakelockPlus.disable();
      } catch (_) {}
    }
    super.dispose();
  }

  void _applyWakelock() async {
    try {
      if (_wakelockEnabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  void _triggerHaptic() {
    if (_hapticsEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp) {
      huntProvider.increment(widget.huntId);
      _triggerHaptic();
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.minus) {
      if (!_isLockMode) {
        huntProvider.decrement(widget.huntId);
        _triggerHaptic();
      }
    } else if (key == LogicalKeyboardKey.keyP) {
      final hunt = huntProvider.getHuntById(widget.huntId);
      if (hunt != null) {
        if (hunt.isActive) {
          huntProvider.pauseHunt(widget.huntId);
        } else if (hunt.isPaused) {
          huntProvider.resumeHunt(widget.huntId);
        }
      }
    }
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _calculatePacePerHour(int encounters, int totalSeconds) {
    if (totalSeconds <= 0 || encounters <= 0) return 0.0;
    return (encounters / totalSeconds) * 3600.0;
  }

  void _showManualCountDialog(ShinyHunt hunt) {
    final controller = TextEditingController(text: hunt.currentEncounters.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translator.get('shiny_hunt_manual_count_title')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: Translator.get('shiny_hunt_manual_count_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) {
                Provider.of<ShinyHuntProvider>(context, listen: false)
                    .setManualCount(hunt.id, parsed);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(Translator.get('save', fallback: 'Speichern')),
          ),
        ],
      ),
    );
  }

  void _showCustomStepDialog(ShinyHunt hunt) {
    final controller = TextEditingController(text: hunt.incrementStep.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Text(Translator.get('shiny_hunt_step_custom_title', fallback: 'Eigene Schrittweite')),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: Translator.get('shiny_hunt_step_custom_hint', fallback: 'Schrittweite eingeben (z. B. 3, 30)...'),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final parsed = int.tryParse(val.trim());
            if (parsed != null && parsed > 0 && parsed <= 99999) {
              setState(() => _customStep = parsed);
              Provider.of<ShinyHuntProvider>(context, listen: false)
                  .setStep(hunt.id, parsed);
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0 && parsed <= 99999) {
                setState(() => _customStep = parsed);
                Provider.of<ShinyHuntProvider>(context, listen: false)
                    .setStep(hunt.id, parsed);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(Translator.get('save', fallback: 'Speichern')),
          ),
        ],
      ),
    );
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.keyboard, color: Colors.amber),
            const SizedBox(width: 8),
            Text(Translator.get('shiny_hunt_shortcuts_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.space_bar),
              title: Text(Translator.get('shiny_hunt_shortcut_space')),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.arrow_downward),
              title: Text(Translator.get('shiny_hunt_shortcut_down')),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.pause),
              title: Text(Translator.get('shiny_hunt_shortcut_pause')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(ShinyHunt hunt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.flag_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Translator.get('shiny_hunt_finish_dialog_title', fallback: 'Hunt beenden / archivieren'),
              ),
            ),
          ],
        ),
        content: Text(
          Translator.get('shiny_hunt_finish_dialog_desc', fallback: 'Möchtest du diesen Shiny Hunt als gefangen abschließen oder ohne Fang archivieren?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<ShinyHuntProvider>(context, listen: false).completeHunt(hunt.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Translator.get('shiny_hunt_completed_banner', fallback: 'Dieser Shiny Hunt ist abgeschlossen und im Archiv.'),
                    ),
                  ),
                );
              }
            },
            child: Text(Translator.get('shiny_hunt_finish_archive_only', fallback: 'Ohne Fang archivieren')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.auto_awesome, size: 16),
            onPressed: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (_) => ShinyCatchDialog(hunt: hunt),
              );
            },
            label: Text(Translator.get('shiny_hunt_finish_as_caught', fallback: '🎉 Als Shiny gefangen abschließen')),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHistory(ShinyHunt hunt, bool isDark) {
    if (hunt.phaseHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.amber.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                Translator.get('shiny_hunt_phase_history_card_title', fallback: 'Phasen-Shinies'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${hunt.phaseHistory.length} ${hunt.phaseHistory.length == 1 ? "Phase" : "Phasen"}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hunt.phaseHistory.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final phase = hunt.phaseHistory[index];
                final name = phase.caughtPokemonName ?? 'Phase ${phase.phaseNumber}';
                return Chip(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  avatar: phase.caughtPokemonId != null
                      ? UniversalPokeImage(
                          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${phase.caughtPokemonId}.png',
                          width: 20,
                          height: 20,
                        )
                      : const Icon(Icons.star, size: 14, color: Colors.amber),
                  label: Text(
                    Translator.get(
                      'shiny_hunt_phase_badge',
                      fallback: 'Phase {phase}: {name} ({encounters})',
                    )
                        .replaceAll('{phase}', phase.phaseNumber.toString())
                        .replaceAll('{name}', name)
                        .replaceAll('{encounters}', phase.encounters.toString()),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextChips(ShinyHunt hunt, bool isDark) {
    final effectiveHuntingType = hunt.huntingType ?? ShinyHuntOddsHelper.inferHuntingTypeFromMethod(hunt.method);

    DexProvider? dexProvider;
    try {
      dexProvider = Provider.of<DexProvider>(context, listen: false);
    } catch (_) {}

    String? targetDexTitle;
    if (hunt.targetDexId != null && dexProvider != null) {
      targetDexTitle = dexProvider.userDexes.where((d) => d.id == hunt.targetDexId).firstOrNull?.title;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Spiel
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.videogame_asset_outlined, size: 16),
              label: Text(hunt.game, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            // Methode
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.track_changes_outlined, size: 16),
              label: Text('${hunt.method} (1/${hunt.baseOdds.toInt()})', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            // Zeiten & Pausen (Timeline)
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.access_time_rounded, size: 16, color: Colors.amber),
              label: Text(
                hunt.pauseHistory.isNotEmpty
                    ? '${Translator.get('shiny_hunt_timeline_chip', fallback: 'Zeiten & Pausen')} (${hunt.pauseHistory.length})'
                    : Translator.get('shiny_hunt_timeline_chip', fallback: 'Zeiten & Pausen'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: () => ShinyHuntTimelineDialog.show(context, hunt),
            ),
            const SizedBox(width: 6),
            // Jagdart / Herkunft
            if (effectiveHuntingType.isNotEmpty) ...[
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(ShinyHuntOddsHelper.getHuntingTypeIcon(effectiveHuntingType), size: 16),
                label: Text(ShinyHuntOddsHelper.getLocalizedHuntingType(effectiveHuntingType), style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
            ],
            // Ziel-Dex
            if (targetDexTitle != null) ...[
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.book_outlined, size: 16),
                label: Text(targetDexTitle, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
            ],
            // Schillerpin
            if (hunt.hasShinyCharm) ...[
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                label: Text(
                  Translator.get('shiny_hunt_charm_badge', fallback: 'Schillerpin'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Form falls vorhanden
            if (hunt.pokemonFormId != null) ...[
              Builder(
                builder: (context) {
                  String label = '${Translator.get('shiny_hunt_form_label', fallback: 'Form')} #${hunt.pokemonFormId}';
                  if (dexProvider != null && hunt.pokemonFormId! > 0) {
                    final pokemon = dexProvider.allPokemon.where((p) => p.id == hunt.pokemonId).firstOrNull;
                    final form = pokemon?.forms.where((f) => (f.imageId > 0 ? f.imageId : pokemon.id) == hunt.pokemonFormId).firstOrNull;
                    if (form != null) {
                      label = DexLogicHelper.getFormDisplayName(form.name);
                    }
                  }
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.style_outlined, size: 16),
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
            // Notizen falls vorhanden
            if (hunt.notes != null && hunt.notes!.trim().isNotEmpty) ...[
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.notes_rounded, size: 16),
                label: Text(
                  hunt.notes!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.notes_rounded, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(Translator.get('notes', fallback: 'Notizen')),
                        ],
                      ),
                      content: Text(hunt.notes!.trim()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCatchDetailsCard(ShinyHunt hunt, bool isDark, ShinyHuntProvider huntProvider) {
    Map<String, String> ballUrls = const {};
    try {
      ballUrls = Provider.of<DexProvider>(context, listen: false).ballUrls;
    } catch (_) {}

    final ballImgUrl = hunt.ballUsed != null ? ballUrls[hunt.ballUsed] : null;

    String? dateLabel;
    if (hunt.completedAt != null) {
      final d = hunt.completedAt!;
      final dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
      dateLabel = hunt.ballUsed != null
          ? Translator.get('shiny_hunt_caught_on', fallback: 'Gefangen am {date}').replaceAll('{date}', dateStr)
          : Translator.get('shiny_hunt_archived_on', fallback: 'Archiviert am {date}').replaceAll('{date}', dateStr);
    }

    final effectiveHuntingType = hunt.huntingType ?? ShinyHuntOddsHelper.inferHuntingTypeFromMethod(hunt.method);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.green.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hunt.ballUsed != null ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
                color: hunt.ballUsed != null ? Colors.amber.shade700 : Colors.green,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translator.get('shiny_hunt_catch_details_title', fallback: 'Fang-Details'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      Translator.get('shiny_hunt_completed_banner', fallback: 'Dieser Shiny Hunt ist abgeschlossen und im Archiv.'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
                tooltip: Translator.get('shiny_hunt_reopen_btn', fallback: 'Hunt wieder aufnehmen'),
                onPressed: () async {
                  await huntProvider.reopenHunt(hunt.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Translator.get('shiny_hunt_reopened_toast', fallback: 'Hunt wurde wieder aktiviert!'),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (dateLabel != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              if (hunt.ballUsed != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ballImgUrl != null) ...[
                      UniversalPokeImage(
                        imageUrl: ballImgUrl,
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 4),
                    ] else ...[
                      const Text('⚾ ', style: TextStyle(fontSize: 12)),
                    ],
                    Text(
                      ShinyHuntOddsHelper.getLocalizedBallName(hunt.ballUsed),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${Translator.get('shiny_hunt_started_label', fallback: 'Gestartet')}: ${hunt.createdAt.day.toString().padLeft(2, '0')}.${hunt.createdAt.month.toString().padLeft(2, '0')}.${hunt.createdAt.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => ShinyHuntTimelineDialog.show(context, hunt),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${hunt.pauseHistory.length} ${hunt.pauseHistory.length == 1 ? Translator.get('shiny_hunt_pause_label', fallback: 'Pause') : Translator.get('shiny_hunt_pauses_label', fallback: 'Pausen')}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.amber),
                    ],
                  ),
                ),
              ),
              if (effectiveHuntingType.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ShinyHuntOddsHelper.getHuntingTypeIcon(effectiveHuntingType), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      ShinyHuntOddsHelper.getLocalizedHuntingType(effectiveHuntingType),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          if (hunt.notes != null && hunt.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hunt.notes!.trim(),
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translator.get('shiny_hunt_settings_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(Translator.get('shiny_hunt_setting_haptics')),
                secondary: const Icon(Icons.vibration),
                value: _hapticsEnabled,
                onChanged: (val) {
                  setSheetState(() => _hapticsEnabled = val);
                  setState(() => _hapticsEnabled = val);
                },
              ),
              SwitchListTile(
                title: Text(Translator.get('shiny_hunt_setting_wakelock')),
                secondary: const Icon(Icons.screen_lock_portrait),
                value: _wakelockEnabled,
                onChanged: (val) {
                  setSheetState(() => _wakelockEnabled = val);
                  setState(() {
                    _wakelockEnabled = val;
                    _applyWakelock();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final huntProvider = Provider.of<ShinyHuntProvider>(context);
    final hunt = huntProvider.getHuntById(widget.huntId);

    if (hunt == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Translator.get('shiny_hunt_hub_title'))),
        body: const Center(child: Text('Hunt nicht gefunden.')),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pProb = ShinyHuntOddsHelper.calculateEffectiveProbability(hunt);
    final qProb = ShinyHuntOddsHelper.calculateEffectiveComplementProbability(hunt);
    final ratio = ShinyHuntOddsHelper.calculateOddsRatio(
      hunt.currentPhaseRolls,
      hunt.baseOdds,
    );
    final classification = ShinyHuntOddsHelper.getClassification(
      hunt.currentPhaseRolls,
      hunt.baseOdds,
    );

    final pace = _calculatePacePerHour(hunt.totalEncounters, hunt.totalTimeSeconds);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName,
                style: const TextStyle(fontSize: 18),
              ),
              if (hunt.title.isNotEmpty && hunt.title != hunt.pokemonName)
                Text(
                  hunt.pokemonName,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          actions: [
            // 🔒 Tap-Only-Lock Toggle
            IconButton(
              icon: Icon(
                _isLockMode ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: _isLockMode ? Colors.amber : null,
              ),
              tooltip: Translator.get('shiny_hunt_lock_mode_title'),
              onPressed: () {
                setState(() => _isLockMode = !_isLockMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1500),
                    content: Text(
                      _isLockMode
                          ? '🔒 Tap-Only Modus aktiviert (Schutz vor Fehlklicks)'
                          : '🔓 Tap-Only Modus deaktiviert',
                    ),
                  ),
                );
              },
            ),
            if (!_isLockMode && !hunt.isCompleted) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                icon: const Icon(Icons.flag_rounded, size: 16),
                label: Text(
                  Translator.get('shiny_hunt_finish_btn', fallback: 'Beenden'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showFinishDialog(hunt),
              ),
              const SizedBox(width: 4),
            ],
            if (!_isLockMode) ...[
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: Translator.get('shiny_hunt_shortcuts_title'),
                onPressed: _showShortcutsDialog,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: Translator.get('shiny_hunt_settings_title'),
                onPressed: _showSettingsSheet,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Hunt bearbeiten',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CreateEditHuntDialog(existingHunt: hunt),
                  );
                },
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Wahrscheinlichkeits-Cockpit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: classification.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: classification.color, width: 1.5),
                      ),
                      child: Text(
                        classification.label,
                        style: TextStyle(
                          color: classification.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(pProb * 100.0).toStringAsFixed(1)}% ${Translator.get('shiny_hunt_chance_at_least_one')}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${(qProb * 100.0).toStringAsFixed(1)}% ${Translator.get('shiny_hunt_chance_none_yet')} • ${ratio.toStringAsFixed(2)}x Odds',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Zeit & Pace
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hunt.isCompleted) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: Icon(
                              hunt.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 18,
                            ),
                            label: Text(
                              hunt.isPaused
                                  ? Translator.get('shiny_hunt_resume_hunt_btn', fallback: 'Fortsetzen')
                                  : Translator.get('shiny_hunt_pause_hunt_btn', fallback: 'Pausieren'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              if (hunt.isPaused) {
                                huntProvider.resumeHunt(hunt.id);
                              } else {
                                huntProvider.pauseHunt(hunt.id);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(hunt.totalTimeSeconds),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${pace.toStringAsFixed(0)} / h',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Kontext-Info Chips
              _buildContextChips(hunt, isDark),

              // Fang-Details wenn abgeschlossen
              if (hunt.isCompleted)
                _buildCatchDetailsCard(hunt, isDark, huntProvider),

              // Phasen-Historie
              _buildPhaseHistory(hunt, isDark),

              // 2. Große Tap-Zone & Sprite-Bereich
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    final spriteSize = (maxH * 0.38).clamp(60.0, 160.0);
                    final numberFontSize = (maxH * 0.18).clamp(36.0, 72.0);
                    final spacing = (maxH * 0.02).clamp(2.0, 12.0);

                    return GestureDetector(
                      key: _counterAreaKey,
                      behavior: HitTestBehavior.opaque,
                      onTap: hunt.isCompleted
                          ? null
                          : () {
                              huntProvider.increment(hunt.id);
                              _triggerHaptic();
                            },
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Sprite mit Shiny/Normal Toggle
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  UniversalPokeImage(
                                    imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${_showShinySprite ? "shiny/" : ""}${hunt.effectiveSpriteId}.png',
                                    fallbackUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${_showShinySprite ? "shiny/" : ""}${hunt.effectiveSpriteId}.png',
                                    width: spriteSize,
                                    height: spriteSize,
                                  ),
                                  if (!_isLockMode)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: InkWell(
                                        onTap: () => setState(() => _showShinySprite = !_showShinySprite),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _showShinySprite ? Colors.amber : Colors.grey.shade600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _showShinySprite
                                                ? Translator.get('shiny_hunt_sprite_toggle_shiny')
                                                : Translator.get('shiny_hunt_sprite_toggle_normal'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: spacing),

                              // Riesige Encounter-Anzeige (antippbar für manuelle Zahl)
                              InkWell(
                                onTap: (_isLockMode || hunt.isCompleted) ? null : () => _showManualCountDialog(hunt),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: Column(
                                    children: [
                                      Text(
                                        hunt.currentEncounters.toString(),
                                        style: TextStyle(
                                          fontSize: numberFontSize,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        hunt.priorPhaseEncounters > 0
                                            ? 'Phase ${hunt.phase} • Gesamt: ${hunt.totalEncounters} (${hunt.totalRolls} ${Translator.get('shiny_hunt_rolls_label')})'
                                            : '${Translator.get('shiny_hunt_total_label')}: ${hunt.totalEncounters} (${hunt.totalRolls} ${Translator.get('shiny_hunt_rolls_label')})',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing),

                              // Tippen-Hinweis oder Fertig-Hinweis
                              if (hunt.isCompleted)
                                Text(
                                  hunt.ballUsed != null
                                      ? '🎉 Gefangen (${hunt.totalEncounters} Encounters)'
                                      : '🏁 Archiviert (${hunt.totalEncounters} Encounters)',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  Translator.get('shiny_hunt_tap_to_count'),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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

              // 3. Schrittweiten & Buttons (ausgeblendet im Lock-Modus)
              if (!_isLockMode) ...[
                if (hunt.isCompleted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              Translator.get('shiny_hunt_back_to_hub', fallback: 'Zurück zur Übersicht'),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              Translator.get('shiny_hunt_reopen_btn', fallback: 'Hunt wieder aufnehmen'),
                            ),
                            onPressed: () async {
                              await huntProvider.reopenHunt(hunt.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      Translator.get('shiny_hunt_reopened_toast', fallback: 'Hunt wurde wieder aktiviert!'),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Schrittweiten-Leiste
                  Padding(
                    key: _buttonsKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Builder(
                        builder: (context) {
                          final customStepVal = _customStep ?? (![1, 5, 10].contains(hunt.incrementStep) ? hunt.incrementStep : null);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...[1, 5, 10].map((step) {
                                final isSel = hunt.incrementStep == step;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text('+$step'),
                                    selected: isSel,
                                    onSelected: (_) {
                                      huntProvider.setStep(hunt.id, step);
                                    },
                                  ),
                                );
                              }),
                              if (customStepVal != null && ![1, 5, 10].contains(customStepVal))
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text('+$customStepVal'),
                                    selected: hunt.incrementStep == customStepVal,
                                    onSelected: (_) {
                                      huntProvider.setStep(hunt.id, customStepVal);
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ActionChip(
                                  avatar: const Icon(Icons.edit, size: 14),
                                  label: Text(
                                    Translator.get('shiny_hunt_step_custom', fallback: 'Custom'),
                                  ),
                                  onPressed: () => _showCustomStepDialog(hunt),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Button-Leiste: Minus (-), Phasen-Shiny, Fang, Plus (+)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // Minus Button
                        IconButton.filledTonal(
                          iconSize: 28,
                          onPressed: hunt.currentEncounters > 0
                              ? () {
                                  huntProvider.decrement(hunt.id);
                                  _triggerHaptic();
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 8),

                        // Phasen-Shiny & Shiny Gefangen
                        Expanded(
                          flex: 3,
                          child: Container(
                            key: _phasesActionsKey,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => RecordPhaseDialog(hunt: hunt),
                                      );
                                    },
                                    icon: const Icon(Icons.history_toggle_off, size: 18),
                                    label: Text(
                                      Translator.get('shiny_hunt_record_phase_btn'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () async {
                                      final caught = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => ShinyCatchDialog(hunt: hunt),
                                      );
                                      if (caught == true && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.amber.shade800,
                                            content: Text('🎉 Glückwunsch! ${hunt.pokemonName} wurde gefangen und der Hunt beendet!'),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.auto_awesome),
                                    label: Text(
                                      Translator.get('shiny_hunt_caught_btn'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Plus Button
                        IconButton.filled(
                          iconSize: 28,
                          onPressed: () {
                            huntProvider.increment(hunt.id);
                            _triggerHaptic();
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
