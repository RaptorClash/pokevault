import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/shiny_hunt.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/shiny_hunt_provider.dart';
import '../../../services/database_service.dart';
import '../../../utils/shiny_hunt_odds_helper.dart';
import '../../../l10n/app_translations.dart';
import '../../../widgets/universal_poke_image.dart';

class ShinyCatchDialog extends StatefulWidget {
  final ShinyHunt hunt;
  final DatabaseService? databaseService;

  const ShinyCatchDialog({
    super.key,
    required this.hunt,
    this.databaseService,
  });

  @override
  State<ShinyCatchDialog> createState() => _ShinyCatchDialogState();
}

class _ShinyCatchDialogState extends State<ShinyCatchDialog> {
  String _selectedBall = 'poke-ball';
  Map<String, String> _ballUrls = {};
  Set<String> _matchingBallKeys = {};
  bool _isLoadingBalls = true;

  bool _saveToDex = true;
  String? _selectedDexId;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDexId = widget.hunt.targetDexId;
    _loadBalls();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getLocalizedBallName(String ballKey) {
    return ShinyHuntOddsHelper.getLocalizedBallName(ballKey);
  }

  Future<void> _loadBalls() async {
    try {
      final db = widget.databaseService ?? DatabaseService.instance;
      final urls = await db.getBallUrls();
      final targetUid = widget.hunt.targetUniqueId ?? '${widget.hunt.pokemonId}_normal';
      var matchingData = await db.getMatchingBalls(targetUid);
      if (matchingData == null && targetUid != '${widget.hunt.pokemonId}_normal') {
        matchingData = await db.getMatchingBalls('${widget.hunt.pokemonId}_normal');
      }
      final shinyList = List<String>.from(matchingData?['shiny'] ?? []);
      final normalList = List<String>.from(matchingData?['normal'] ?? []);
      final targetMatching = shinyList.isNotEmpty ? shinyList : normalList;
      final matchingKeys = targetMatching.map((k) => k.replaceAll('-', '_').toLowerCase()).toSet();

      if (mounted) {
        final sortedEntries = urls.entries.toList()
          ..sort((a, b) {
            final aClean = a.key.replaceAll('-', '_').toLowerCase();
            final bClean = b.key.replaceAll('-', '_').toLowerCase();
            final aMatch = matchingKeys.contains(aClean);
            final bMatch = matchingKeys.contains(bClean);
            if (aMatch && !bMatch) return -1;
            if (!aMatch && bMatch) return 1;
            return a.key.compareTo(b.key);
          });

        final sortedMap = Map.fromEntries(sortedEntries);

        setState(() {
          _ballUrls = sortedMap;
          _matchingBallKeys = matchingKeys;
          if (matchingKeys.isNotEmpty && sortedMap.containsKey(sortedEntries.first.key)) {
            _selectedBall = sortedEntries.first.key;
          } else if (_ballUrls.containsKey('luxury_ball') || _ballUrls.containsKey('luxury-ball')) {
            _selectedBall = _ballUrls.containsKey('luxury_ball') ? 'luxury_ball' : 'luxury-ball';
          } else if (_ballUrls.isNotEmpty) {
            _selectedBall = _ballUrls.keys.first;
          }
          _isLoadingBalls = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBalls = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dexProvider = Provider.of<DexProvider>(context);
    final userDexes = dexProvider.userDexes;

    final targetDex = widget.hunt.targetDexId != null
        ? userDexes.where((d) => d.id == widget.hunt.targetDexId).firstOrNull
        : null;

    final effectiveDexId = targetDex?.id ??
        (userDexes.any((d) => d.id == _selectedDexId)
            ? _selectedDexId
            : (userDexes.isNotEmpty ? userDexes.first.id : null));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header mit Glitzer / Feier
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.amber.shade900.withValues(alpha: 0.3), Colors.purple.shade900.withValues(alpha: 0.3)]
                          : [Colors.amber.shade100, Colors.purple.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade400, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 42),
                      const SizedBox(height: 8),
                      Text(
                        Translator.get('shiny_hunt_catch_dialog_title'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.hunt.pokemonName} (${widget.hunt.totalEncounters} Encounters)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ball-Auswahl
                Text(
                  Translator.get('shiny_hunt_ball_select'),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_isLoadingBalls)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (_ballUrls.isNotEmpty)
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ballUrls.keys.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final ballName = _ballUrls.keys.elementAt(index);
                        final ballUrl = _ballUrls[ballName] ?? '';
                        final isSelected = _selectedBall == ballName;
                        final isMatching = _matchingBallKeys.contains(ballName.replaceAll('-', '_').toLowerCase());
                        final localizedName = _getLocalizedBallName(ballName);
                        final tooltipMsg = isMatching
                            ? '$localizedName ✨ (${Translator.get('shiny_hunt_matching_ball_badge', fallback: 'Matching Ball')})'
                            : localizedName;

                        return Tooltip(
                          message: tooltipMsg,
                          child: InkWell(
                            onTap: () => setState(() => _selectedBall = ballName),
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.amber.withValues(alpha: 0.25)
                                        : (isMatching
                                            ? Colors.amber.withValues(alpha: 0.08)
                                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.amber
                                          : (isMatching ? Colors.amber.withValues(alpha: 0.6) : Colors.transparent),
                                      width: isSelected ? 2.5 : (isMatching ? 1.5 : 1),
                                    ),
                                  ),
                                  child: UniversalPokeImage(
                                    imageUrl: ballUrl,
                                    width: 44,
                                    height: 44,
                                    errorIconSize: 20,
                                  ),
                                ),
                                if (isMatching)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.star, size: 10, color: Colors.black87),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  TextFormField(
                    initialValue: _selectedBall,
                    decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.sports_baseball)),
                    onChanged: (v) => _selectedBall = v,
                  ),
                const SizedBox(height: 16),

                // Dex-Sync Checkbox & Dropdown
                if (userDexes.isNotEmpty) ...[
                  if (targetDex != null) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _saveToDex,
                      onChanged: (val) => setState(() => _saveToDex = val ?? true),
                      title: Text(
                        Translator.get(
                          'shiny_hunt_sync_to_target_dex',
                          fallback: 'In "{dexTitle}" als gefangen & Shiny markieren',
                        ).replaceAll('{dexTitle}', targetDex.title),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Pokémon #${widget.hunt.pokemonId} wird im verknüpften Dex aktualisiert',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ] else ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _saveToDex,
                      onChanged: (val) => setState(() => _saveToDex = val ?? true),
                      title: Text(Translator.get('shiny_hunt_save_to_dex')),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_saveToDex) ...[
                      DropdownButtonFormField<String>(
                        initialValue: effectiveDexId,
                        decoration: InputDecoration(
                          labelText: Translator.get('shiny_hunt_target_dex'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: userDexes.map((d) {
                          return DropdownMenuItem<String>(
                            value: d.id,
                            child: Text(d.title),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDexId = val),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],

                // Notizen
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: Translator.get('shiny_hunt_notes'),
                    hintText: 'Z. B. Mäßig, 5 DVs, Luxusball...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Aktionen
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () async {
                        final huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
                        await huntProvider.completeHunt(
                          widget.hunt.id,
                          ballUsed: _selectedBall,
                          targetDexId: _saveToDex ? effectiveDexId : null,
                          targetUniqueId: widget.hunt.targetUniqueId,
                          dexProvider: dexProvider,
                          notes: _notesController.text.trim().isNotEmpty
                              ? _notesController.text.trim()
                              : null,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: Text(Translator.get('confirm', fallback: 'Fang eintragen')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
