import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shiny_hunt.dart';
import '../../providers/dex_provider.dart';
import '../../providers/shiny_hunt_provider.dart';
import '../../utils/shiny_hunt_odds_helper.dart';
import '../../l10n/app_translations.dart';
import '../../widgets/universal_poke_image.dart';
import 'shiny_hunt_counter_screen.dart';
import 'dialogs/create_edit_hunt_dialog.dart';
import 'dialogs/shiny_hunt_timeline_dialog.dart';

class ShinyHuntsHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const ShinyHuntsHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ShinyHuntsHubScreen> createState() => _ShinyHuntsHubScreenState();
}

class _ShinyHuntsHubScreenState extends State<ShinyHuntsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openCounter(String huntId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShinyHuntCounterScreen(huntId: huntId),
      ),
    );
  }

  void _openCreateDialog() async {
    final created = await showDialog<ShinyHunt?>(
      context: context,
      builder: (_) => const CreateEditHuntDialog(),
    );
    if (created != null && mounted) {
      _openCounter(created.id);
    }
  }

  void _confirmDeleteHunt(ShinyHunt hunt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translator.get('shiny_hunt_delete_confirm_title')),
        content: Text(Translator.get('shiny_hunt_delete_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<ShinyHuntProvider>(context, listen: false).deleteHunt(hunt.id);
              Navigator.of(ctx).pop();
            },
            child: Text(Translator.get('delete', fallback: 'Löschen')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $hh:$mm';
  }

  List<ShinyHunt> _filterHunts(List<ShinyHunt> hunts) {
    if (_searchQuery.trim().isEmpty) return hunts;
    final q = _searchQuery.trim().toLowerCase();
    DexProvider? dexProvider;
    try {
      dexProvider = Provider.of<DexProvider>(context, listen: false);
    } catch (_) {}

    return hunts.where((h) {
      final name = h.pokemonName.toLowerCase();
      final title = h.title.toLowerCase();
      final game = h.game.toLowerCase();
      final method = h.method.toLowerCase();
      final notes = (h.notes ?? '').toLowerCase();
      final id = h.pokemonId.toString();

      final poke = dexProvider?.allPokemon.where((p) => p.id == h.pokemonId).firstOrNull;
      final de = poke?.nameDe.toLowerCase() ?? '';
      final en = poke?.nameEn.toLowerCase() ?? '';

      return name.contains(q) ||
          title.contains(q) ||
          game.contains(q) ||
          method.contains(q) ||
          notes.contains(q) ||
          id == q ||
          de.contains(q) ||
          en.contains(q);
    }).toList();
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              Translator.get('shiny_hunt_search_no_results', fallback: 'Keine Shiny Hunts gefunden für "{query}".')
                  .replaceAll('{query}', _searchQuery),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Text(Translator.get('clear', fallback: 'Suche zurücksetzen')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: Translator.get(
            'shiny_hunt_search_hint',
            fallback: 'Hunts durchsuchen (Pokémon, Spiel, Notiz)...',
          ),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final huntProvider = Provider.of<ShinyHuntProvider>(context);
    final activeHunts = _filterHunts(huntProvider.activeHunts);
    final pausedHunts = _filterHunts(huntProvider.pausedHunts);
    final completedHunts = _filterHunts(huntProvider.completedHunts);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Text(Translator.get('shiny_hunt_hub_title')),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Translator.get('shiny_hunt_tab_active')),
                  if (activeHunts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge.count(
                      count: activeHunts.length,
                      backgroundColor: Colors.amber.shade700,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Translator.get('shiny_hunt_tab_paused')),
                  if (pausedHunts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge.count(
                      count: pausedHunts.length,
                      backgroundColor: Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Translator.get('shiny_hunt_tab_completed')),
                  if (completedHunts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge.count(
                      count: completedHunts.length,
                      backgroundColor: Colors.green.shade600,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: huntProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveTab(activeHunts),
                      _buildPausedTab(pausedHunts),
                      _buildCompletedTab(completedHunts),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(Translator.get('shiny_hunt_new_hunt')),
      ),
    );
  }

  Widget _buildPhaseBadges(ShinyHunt hunt) {
    if (hunt.phaseHistory.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: hunt.phaseHistory.map((phase) {
          final dateStr =
              '${phase.completedAt.day.toString().padLeft(2, '0')}.${phase.completedAt.month.toString().padLeft(2, '0')}.${phase.completedAt.year}';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.purpleAccent),
                const SizedBox(width: 4),
                Text(
                  'Phase ${phase.phaseNumber}: ${phase.caughtPokemonName ?? 'Shiny'} (${phase.encounters}) • $dateStr',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTab(List<ShinyHunt> hunts) {
    if (hunts.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return _buildEmptySearchState();
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flare, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                Translator.get('shiny_hunt_empty_active'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: Text(Translator.get('shiny_hunt_new_hunt')),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: hunts.length,
      itemBuilder: (context, index) {
        final hunt = hunts[index];
        final pProb = ShinyHuntOddsHelper.calculateEffectiveProbability(hunt);
        final classification = ShinyHuntOddsHelper.getClassification(hunt.currentPhaseRolls, hunt.baseOdds);
        final ratio = ShinyHuntOddsHelper.calculateOddsRatio(hunt.currentPhaseRolls, hunt.baseOdds);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openCounter(hunt.id),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      UniversalPokeImage(
                        imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${hunt.effectiveSpriteId}.png',
                        width: 56,
                        height: 56,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${hunt.game} • ${hunt.method}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => ShinyHuntTimelineDialog.show(context, hunt),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${Translator.get('shiny_hunt_started', fallback: 'Start')}: ${_formatDate(hunt.createdAt)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => ShinyHuntTimelineDialog.show(context, hunt),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: hunt.pauseHistory.isNotEmpty
                                          ? Colors.orange.withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: hunt.pauseHistory.isNotEmpty
                                            ? Colors.orange.withValues(alpha: 0.3)
                                            : Colors.grey.withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hunt.pauseHistory.isNotEmpty ? Icons.history_toggle_off : Icons.history_rounded,
                                          size: 11,
                                          color: hunt.pauseHistory.isNotEmpty ? Colors.orange.shade800 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          hunt.pauseHistory.isNotEmpty
                                              ? '${hunt.pauseHistory.length} ${hunt.pauseHistory.length == 1 ? 'Pause' : 'Pausen'}'
                                              : Translator.get('shiny_hunt_timeline_btn', fallback: 'Zeiten'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: hunt.pauseHistory.isNotEmpty
                                                ? Colors.orange.shade900
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hunt.currentEncounters} Encounters (${hunt.currentPhaseRolls} Rolls)',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Quick +1 & Pause
                      Column(
                        children: [
                          IconButton.filled(
                            iconSize: 22,
                            onPressed: () {
                              Provider.of<ShinyHuntProvider>(context, listen: false).increment(hunt.id);
                            },
                            icon: const Icon(Icons.add),
                            tooltip: '+${hunt.incrementStep}',
                          ),
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.pause),
                            tooltip: Translator.get('shiny_hunt_pause'),
                            onPressed: () {
                              Provider.of<ShinyHuntProvider>(context, listen: false).pauseHunt(hunt.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar & Percentage
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pProb.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(classification.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(pProb * 100.0).toStringAsFixed(1)}% (${ratio.toStringAsFixed(2)}x)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: classification.color,
                        ),
                      ),
                    ],
                  ),
                  _buildPhaseBadges(hunt),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPausedTab(List<ShinyHunt> hunts) {
    if (hunts.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return _buildEmptySearchState();
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            Translator.get('shiny_hunt_empty_paused'),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: hunts.length,
      itemBuilder: (context, index) {
        final hunt = hunts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                onTap: () => _openCounter(hunt.id),
                leading: UniversalPokeImage(
                  imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${hunt.effectiveSpriteId}.png',
                  width: 48,
                  height: 48,
                ),
                title: Text(hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${hunt.currentEncounters} Encounters • ${hunt.game}'),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.pause_circle_outline, size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hunt.pauseHistory.isNotEmpty
                                ? '${Translator.get('shiny_hunt_paused_since', fallback: 'Pausiert seit')} ${_formatDateTime(hunt.pauseHistory.last.pausedAt)}'
                                : Translator.get('shiny_hunt_tab_paused', fallback: 'Pausiert'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: Colors.grey),
                      tooltip: Translator.get('shiny_hunt_timeline_title', fallback: 'Timeline & Pausen'),
                      onPressed: () => ShinyHuntTimelineDialog.show(context, hunt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      tooltip: Translator.get('shiny_hunt_resume'),
                      onPressed: () {
                        Provider.of<ShinyHuntProvider>(context, listen: false).resumeHunt(hunt.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: Translator.get('delete', fallback: 'Löschen'),
                      onPressed: () => _confirmDeleteHunt(hunt),
                    ),
                  ],
                ),
              ),
              if (hunt.phaseHistory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildPhaseBadges(hunt),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(List<ShinyHunt> hunts) {
    if (hunts.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return _buildEmptySearchState();
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            Translator.get('shiny_hunt_empty_completed'),
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Map<String, String> ballUrls = const {};
    try {
      ballUrls = Provider.of<DexProvider>(context, listen: false).ballUrls;
    } catch (_) {}

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: hunts.length,
      itemBuilder: (context, index) {
        final hunt = hunts[index];
        final pProb = ShinyHuntOddsHelper.calculateProbability(hunt.baseOdds, hunt.totalRolls);
        final classification = ShinyHuntOddsHelper.getClassification(hunt.totalRolls, hunt.baseOdds);
        final effectiveHuntingType = hunt.huntingType ?? ShinyHuntOddsHelper.inferHuntingTypeFromMethod(hunt.method);
        final ballImgUrl = hunt.ballUsed != null ? ballUrls[hunt.ballUsed] : null;

        String? dateLabel;
        if (hunt.completedAt != null) {
          final d = hunt.completedAt!;
          final dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
          dateLabel = hunt.ballUsed != null
              ? Translator.get('shiny_hunt_caught_on', fallback: 'Gefangen am {date}').replaceAll('{date}', dateStr)
              : Translator.get('shiny_hunt_archived_on', fallback: 'Archiviert am {date}').replaceAll('{date}', dateStr);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openCounter(hunt.id),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      UniversalPokeImage(
                        imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/${hunt.effectiveSpriteId}.png',
                        fallbackUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${hunt.effectiveSpriteId}.png',
                        width: 60,
                        height: 60,
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${hunt.totalEncounters} Encounters • ${hunt.game}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${Translator.get('shiny_hunt_started', fallback: 'Start')}: ${_formatDate(hunt.createdAt)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            if (hunt.pauseHistory.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => ShinyHuntTimelineDialog.show(context, hunt),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.history_toggle_off, size: 11, color: Colors.purple),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${hunt.pauseHistory.length} ${hunt.pauseHistory.length == 1 ? 'Pause' : 'Pausen'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (dateLabel != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                hunt.ballUsed != null ? Icons.emoji_events_outlined : Icons.archive_outlined,
                                size: 14,
                                color: hunt.ballUsed != null ? Colors.amber.shade700 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: hunt.ballUsed != null ? Colors.amber.shade800 : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: classification.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${classification.label} (${(pProb * 100.0).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: classification.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (effectiveHuntingType.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(ShinyHuntOddsHelper.getHuntingTypeIcon(effectiveHuntingType), size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      ShinyHuntOddsHelper.getLocalizedHuntingType(effectiveHuntingType),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            if (hunt.ballUsed != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (ballImgUrl != null) ...[
                                      UniversalPokeImage(
                                        imageUrl: ballImgUrl,
                                        width: 14,
                                        height: 14,
                                      ),
                                      const SizedBox(width: 4),
                                    ] else ...[
                                      const Text('⚾ ', style: TextStyle(fontSize: 10)),
                                    ],
                                    Text(
                                      ShinyHuntOddsHelper.getLocalizedBallName(hunt.ballUsed),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (hunt.notes != null && hunt.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notes_rounded, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    hunt.notes!.trim(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _buildPhaseBadges(hunt),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.history_rounded, color: Colors.purple),
                        tooltip: Translator.get('shiny_hunt_timeline_title', fallback: 'Timeline & Pausen'),
                        onPressed: () => ShinyHuntTimelineDialog.show(context, hunt),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
                        tooltip: Translator.get('shiny_hunt_reopen_btn', fallback: 'Hunt wieder aufnehmen'),
                        onPressed: () async {
                          await Provider.of<ShinyHuntProvider>(context, listen: false).reopenHunt(hunt.id);
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        tooltip: Translator.get('delete', fallback: 'Löschen'),
                        onPressed: () => _confirmDeleteHunt(hunt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
