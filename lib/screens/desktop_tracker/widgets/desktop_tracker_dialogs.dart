import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/desktop_tracker/desktop_capture_driver.dart';
import '../../../services/desktop_tracker/desktop_window_source.dart';
import '../../../services/desktop_tracker/tracker_alert_service.dart';
import '../../../services/scanner_core/engine/pokemon_fuzzy_matcher.dart';
import '../../../services/scanner_core/models/scanner_event.dart';
import '../controllers/desktop_tracker_dex_controller.dart';
import 'live_frame_thumbnail.dart';

/// Collection of modal dialogs used by [DesktopTrackerScreen].
class DesktopTrackerDialogs {
  static void showAlertSettings(
    BuildContext context, {
    required TrackerAlertService alertService,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final settings = alertService.settings;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Color(0xFFFBC02D),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Alarm- & Signal-Einstellungen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      key: const Key('switch_sound_enabled'),
                      title: const Text(
                        'Akustische Signale (Töne)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        'Spielt Signal-Töne bei Spielereignissen ab',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: settings.soundEnabled,
                      onChanged: (val) {
                        setDialogState(() {
                          alertService.updateSettings(
                            settings.copyWith(soundEnabled: val),
                          );
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('switch_sound_shiny'),
                      title: const Text(
                        '✨ Schillernde Pokémon (Shiny-Gong)',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: settings.soundOnShiny,
                      onChanged: settings.soundEnabled
                          ? (val) {
                              setDialogState(() {
                                alertService.updateSettings(
                                  settings.copyWith(soundOnShiny: val),
                                );
                              });
                            }
                          : null,
                    ),
                    SwitchListTile(
                      key: const Key('switch_sound_alpha'),
                      title: const Text(
                        '🔴 Alpha- & Herrscher-Pokémon',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: settings.soundOnAlpha,
                      onChanged: settings.soundEnabled
                          ? (val) {
                              setDialogState(() {
                                alertService.updateSettings(
                                  settings.copyWith(soundOnAlpha: val),
                                );
                              });
                            }
                          : null,
                    ),
                    SwitchListTile(
                      key: const Key('switch_sound_normal'),
                      title: const Text(
                        '⚪ Normale Fänge / Begegnungen',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: settings.soundOnNormal,
                      onChanged: settings.soundEnabled
                          ? (val) {
                              setDialogState(() {
                                alertService.updateSettings(
                                  settings.copyWith(soundOnNormal: val),
                                );
                              });
                            }
                          : null,
                    ),
                    const Divider(),
                    SwitchListTile(
                      key: const Key('switch_visual_glow'),
                      title: const Text(
                        'Optischer Glow & Pulsieren bei Shiny',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: settings.visualGlowEnabled,
                      onChanged: (val) {
                        setDialogState(() {
                          alertService.updateSettings(
                            settings.copyWith(visualGlowEnabled: val),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Schließen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildEnlargedCanvas({
    required CapturedFrame? liveFrame,
    required Uint8List? fallbackPng,
  }) {
    return Container(
      color: Colors.black,
      child: LiveFrameThumbnail(
        liveFrame: liveFrame,
        fallbackPngBytes: fallbackPng,
        fallbackIcon: Icons.crop_free,
      ),
    );
  }

  static Widget _buildEnlargedLiveStatusBar({
    required String ocrText,
    int? scanCount,
  }) {
    final hasText = ocrText.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent,
            ),
          ),
          if (scanCount != null && scanCount > 0) ...[
            const SizedBox(width: 6),
            Text(
              '#$scanCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              key: const Key('enlarged_preview_ocr_text'),
              hasText ? 'OCR: $ocrText' : 'Warte auf Text...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
                color: hasText ? null : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showEnlargedPreview(
    BuildContext context, {
    required CapturedFrame? liveFrame,
    required Uint8List? fallbackPng,
    required String title,
    ValueListenable<LiveOcrScanStatus>? statusListenable,
    ValueListenable<CapturedFrame?>? frameListenable,
    ValueListenable<Map<String, CapturedFrame>>? boxFramesListenable,
    ValueListenable<Map<String, String>>? boxPreviewsListenable,
    String? boxKey,
  }) {
    if (liveFrame == null &&
        fallbackPng == null &&
        statusListenable == null &&
        frameListenable == null &&
        boxFramesListenable == null) {
      return;
    }
    final hasStatusBar = statusListenable != null ||
        (boxPreviewsListenable != null && boxKey != null);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('enlarged_preview_dialog'),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 640,
          height: hasStatusBar ? 404 : 360,
          child: statusListenable != null
              ? ValueListenableBuilder<LiveOcrScanStatus>(
                  valueListenable: statusListenable,
                  builder: (_, status, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildEnlargedCanvas(
                          liveFrame: status.latestFrame ?? liveFrame,
                          fallbackPng: fallbackPng,
                        ),
                      ),
                      _buildEnlargedLiveStatusBar(
                        ocrText: status.previewText,
                        scanCount: status.scanCount,
                      ),
                    ],
                  ),
                )
              : (boxFramesListenable != null || boxPreviewsListenable != null) &&
                      boxKey != null
                  ? ListenableBuilder(
                      listenable: Listenable.merge([
                        ?boxFramesListenable,
                        ?boxPreviewsListenable,
                      ]),
                      builder: (_, _) {
                        final boxFrame =
                            boxFramesListenable?.value[boxKey] ?? liveFrame;
                        final boxOcr = boxPreviewsListenable?.value[boxKey] ?? '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildEnlargedCanvas(
                                liveFrame: boxFrame,
                                fallbackPng: fallbackPng,
                              ),
                            ),
                            if (boxPreviewsListenable != null)
                              _buildEnlargedLiveStatusBar(ocrText: boxOcr),
                          ],
                        );
                      },
                    )
                  : frameListenable != null
                      ? ValueListenableBuilder<CapturedFrame?>(
                          valueListenable: frameListenable,
                          builder: (_, frame, _) => _buildEnlargedCanvas(
                            liveFrame: frame ?? liveFrame,
                            fallbackPng: fallbackPng,
                          ),
                        )
                      : _buildEnlargedCanvas(
                          liveFrame: liveFrame,
                          fallbackPng: fallbackPng,
                        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  static Future<void> showEventCorrection(
    BuildContext context, {
    required ScannerEvent event,
    required PokemonFuzzyMatcher matcher,
    required Future<void> Function({
      required int newPokemonId,
      required String newPokemonName,
      required bool isShiny,
      required bool isAlpha,
    }) onCorrect,
    required Future<void> Function() onDelete,
    required void Function(int pokemonId, String displayName) onIgnoreTeam,
  }) async {
    final dexProvider = Provider.of<DexProvider>(context, listen: false);
    final allPokemon = dexProvider.allPokemon;
    final pokemonMap = <int, Pokemon>{for (final p in allPokemon) p.id: p};
    String query = '';
    bool shinyDraft = event.isShiny;
    bool alphaDraft = event.isAlpha;

    final rawRankedMap = <int, double>{};
    for (final alt in event.alternatives) {
      final prev = rawRankedMap[alt.pokemonId] ?? 0.0;
      if (alt.confidence > prev) rawRankedMap[alt.pokemonId] = alt.confidence;
    }
    for (final fuzzy in matcher.matchTopK(
      event.rawText,
      limit: 10,
      threshold: 0.20,
    )) {
      final prev = rawRankedMap[fuzzy.pokemonId] ?? 0.0;
      if (fuzzy.confidence > prev) {
        rawRankedMap[fuzzy.pokemonId] = fuzzy.confidence;
      }
    }
    if (event.pokemonId != null && !rawRankedMap.containsKey(event.pokemonId)) {
      rawRankedMap[event.pokemonId!] = event.confidence;
    }

    String resolveCandidateName(int id, [String? fallback]) {
      return pokemonMap[id]?.nameDe ?? fallback ?? '#$id';
    }

    final top10List = DesktopTrackerDexController.buildCorrectionTop10(
      event: event,
      matcher: matcher,
      pokemonMap: pokemonMap,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final q = query.trim().toLowerCase();
            final candidates = <({int id, String name, int? pct})>[];
            final seenIds = <int>{};

            if (q.isEmpty) {
              for (final top in top10List) {
                if (!seenIds.add(top.id)) continue;
                candidates.add((
                  id: top.id,
                  name: top.name,
                  pct: (top.confidence * 100).round().clamp(1, 100),
                ));
              }
            } else {
              final fuzzySearch = matcher.matchTopK(
                q,
                limit: 15,
                threshold: 0.25,
              );
              for (final fuzzy in fuzzySearch) {
                if (!seenIds.add(fuzzy.pokemonId)) continue;
                candidates.add((
                  id: fuzzy.pokemonId,
                  name: resolveCandidateName(
                    fuzzy.pokemonId,
                    fuzzy.canonicalName,
                  ),
                  pct: (fuzzy.confidence * 100).round().clamp(1, 100),
                ));
              }
              for (final Pokemon p in allPokemon) {
                if (seenIds.contains(p.id)) continue;
                final matchesQuery = p.nameDe.toLowerCase().contains(q) ||
                    p.nameEn.toLowerCase().contains(q) ||
                    p.id.toString().contains(q);
                if (matchesQuery) {
                  seenIds.add(p.id);
                  final rawPct = rawRankedMap[p.id];
                  candidates.add((
                    id: p.id,
                    name: p.nameDe,
                    pct: rawPct != null
                        ? (rawPct * 100).round().clamp(1, 100)
                        : null,
                  ));
                  if (candidates.length >= 40) break;
                }
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.auto_fix_high, size: 18, color: Colors.indigoAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ereignis korrigieren',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OCR: "${event.rawText.replaceAll('\n', ' · ')}"',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: const Text(
                              'Shiny ✨',
                              style: TextStyle(fontSize: 11),
                            ),
                            selected: shinyDraft,
                            onSelected: (v) =>
                                setDialogState(() => shinyDraft = v),
                          ),
                          FilterChip(
                            label: const Text(
                              'Alpha',
                              style: TextStyle(fontSize: 11),
                            ),
                            selected: alphaDraft,
                            onSelected: (v) =>
                                setDialogState(() => alphaDraft = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        key: const Key('correction_search_field'),
                        onChanged: (v) => setDialogState(() => query = v),
                        decoration: InputDecoration(
                          hintText: 'Alle Pokémon durchsuchen (Name oder #ID)...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (q.isEmpty && top10List.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'TOP-10 OCR-TREFFER (NACH WAHRSCHEINLICHKEIT)',
                          key: Key('correction_top_candidates_header'),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (candidates.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Kein passendes Pokémon gefunden.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      else
                        ...candidates.map((cand) {
                          final isCurrent = cand.id == event.pokemonId;
                          final pct = cand.pct;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: isCurrent
                                  ? Colors.indigoAccent.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isCurrent
                                      ? Colors.indigoAccent
                                          .withValues(alpha: 0.5)
                                      : Colors.white10,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                key: Key('edit_pick_pokemon_${cand.id}'),
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    color: Colors.black26,
                                    child: Image.network(
                                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${shinyDraft ? 'shiny/' : ''}${cand.id}.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.catching_pokemon,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cand.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '#${cand.id.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: pct != null
                                    ? Container(
                                        key: Key(
                                          'correction_pct_badge_${cand.id}',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (pct >= 70
                                                  ? Colors.green
                                                  : (pct >= 45
                                                      ? Colors.lightBlueAccent
                                                      : Colors.blueGrey))
                                              .withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$pct%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: pct >= 70
                                                ? Colors.greenAccent
                                                : (pct >= 45
                                                    ? Colors.lightBlueAccent
                                                    : Colors.grey.shade300),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right, size: 16),
                                onTap: () async {
                                  Navigator.of(dialogCtx).pop();
                                  await onCorrect(
                                    newPokemonId: cand.id,
                                    newPokemonName: cand.name,
                                    isShiny: shinyDraft,
                                    isAlpha: alphaDraft,
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      if (event.pokemonId != null) ...[
                        const Divider(height: 18),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  Colors.orangeAccent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Eigenes Team / Starter dauerhaft ignorieren?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Sperrt diese Art dauerhaft für künftige OCR-Fänge (z. B. deinen eigenen Starter im Kampfmenü).',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: Key(
                                    'btn_ignore_team_pokemon_${event.pokemonId}',
                                  ),
                                  onPressed: () async {
                                    final targetId = event.pokemonId!;
                                    final targetName = event.matchedName;
                                    onIgnoreTeam(targetId, targetName);
                                    Navigator.of(dialogCtx).pop();
                                    await onDelete();
                                  },
                                  icon: const Icon(
                                    Icons.shield_outlined,
                                    size: 15,
                                    color: Colors.orangeAccent,
                                  ),
                                  label: Text(
                                    '${event.matchedName} dauerhaft ignorieren',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orangeAccent,
                                    side: BorderSide(
                                      color: Colors.orangeAccent
                                          .withValues(alpha: 0.45),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    await onDelete();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Entfernen',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Abbrechen'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
