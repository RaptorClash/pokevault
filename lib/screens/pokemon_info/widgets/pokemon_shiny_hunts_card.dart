import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/shiny_hunt.dart';
import '../../../providers/shiny_hunt_provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../widgets/universal_poke_image.dart';
import '../../shiny_hunt/dialogs/create_edit_hunt_dialog.dart';
import '../../shiny_hunt/shiny_hunt_counter_screen.dart';

class PokemonShinyHuntsCard extends StatelessWidget {
  final DexDisplayEntry entry;
  final String dexId;

  const PokemonShinyHuntsCard({
    super.key,
    required this.entry,
    required this.dexId,
  });

  @override
  Widget build(BuildContext context) {
    ShinyHuntProvider? huntProvider;
    try {
      huntProvider = Provider.of<ShinyHuntProvider>(context);
    } catch (_) {
      huntProvider = null;
    }

    if (huntProvider == null) {
      return const SizedBox.shrink();
    }

    final resolvedForm = entry.resolvedForm;
    final int? currentFormId = resolvedForm?.imageId;
    final bool isBaseForm = resolvedForm == null ||
        resolvedForm.formType == 'normal' ||
        currentFormId == null ||
        currentFormId == 0 ||
        currentFormId == entry.pokemon.id;

    final pokemonHunts = huntProvider.hunts.where((h) {
      if (h.pokemonId != entry.pokemon.id || h.deletedAt != 0) return false;
      // Allgemeine Hunts ohne festgelegte Form werden immer angezeigt
      if (h.pokemonFormId == null) return true;
      if (isBaseForm) {
        // Bei Basisform: Hunts mit Basis-ID oder passender ID
        return h.pokemonFormId == entry.pokemon.id ||
            (currentFormId != null && h.pokemonFormId == currentFormId);
      } else {
        // Bei spezieller Form (z. B. Alola-Raichu): nur Hunts für genau diese Form
        return h.pokemonFormId == currentFormId;
      }
    }).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: pokemonHunts.any((h) => h.isActive) || pokemonHunts.isEmpty,
        leading: const Icon(Icons.track_changes, color: Colors.amber),
        title: Row(
          children: [
            Text(
              Translator.get('shiny_hunt_pokemon_card_title', fallback: 'Shiny Hunts'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (pokemonHunts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pokemonHunts.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pokemonHunts.isEmpty) ...[
                  Text(
                    Translator.get('shiny_hunt_no_hunts_for_pokemon', fallback: 'Keine aktiven Hunts für dieses Pokémon.'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pokemonHunts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final hunt = pokemonHunts[index];
                      final statusColor = hunt.isCompleted
                          ? Colors.green
                          : (hunt.isActive ? Colors.amber : Colors.blueGrey);
                      final statusLabel = hunt.isCompleted
                          ? Translator.get('shiny_hunt_tab_completed', fallback: 'Beendet')
                          : (hunt.isActive
                              ? Translator.get('shiny_hunt_tab_active', fallback: 'Aktiv')
                              : Translator.get('shiny_hunt_tab_paused', fallback: 'Pausiert'));

                      return Material(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShinyHuntCounterScreen(huntId: hunt.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    UniversalPokeImage(
                                      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/${hunt.effectiveSpriteId}.png',
                                      width: 32,
                                      height: 32,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: statusColor, width: 1),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hunt.title.isNotEmpty ? hunt.title : hunt.pokemonName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            hunt.isCompleted && hunt.completedAt != null
                                                ? (hunt.ballUsed != null
                                                    ? '🎉 ${hunt.completedAt!.day.toString().padLeft(2, '0')}.${hunt.completedAt!.month.toString().padLeft(2, '0')}.${hunt.completedAt!.year} • ${hunt.game} (${hunt.ballUsed})'
                                                    : '🏁 ${hunt.completedAt!.day.toString().padLeft(2, '0')}.${hunt.completedAt!.month.toString().padLeft(2, '0')}.${hunt.completedAt!.year} • ${hunt.game}')
                                                : '${hunt.game} • ${hunt.method} (1/${hunt.baseOdds.toInt()})',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${hunt.totalEncounters}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          hunt.phase > 1 ? 'Phase ${hunt.phase}' : 'Encounters',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  ],
                                ),
                                if (hunt.phaseHistory.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: hunt.phaseHistory.map((p) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'Phase ${p.phaseNumber}: ${p.caughtPokemonName ?? "Shiny"} (${p.encounters})',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.purple),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 18),
                    label: Text(
                      Translator.get(
                        'shiny_hunt_start_new_for_pokemon',
                        fallback: '🎯 Neuen Shiny Hunt starten',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final formImgId = entry.resolvedForm?.imageId;
                      final effectiveFormId = (formImgId != null && formImgId > 0)
                          ? formImgId
                          : entry.pokemon.id;

                      final createdHunt = await showDialog<ShinyHunt?>(
                        context: context,
                        builder: (ctx) => CreateEditHuntDialog(
                          initialPokemonId: entry.pokemon.id,
                          initialPokemonName: entry.pokemon.nameDe,
                          initialFormId: effectiveFormId,
                          initialDexId: dexId,
                          initialUniqueId: entry.uniqueId,
                        ),
                      );
                      if (createdHunt != null && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShinyHuntCounterScreen(huntId: createdHunt.id),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
