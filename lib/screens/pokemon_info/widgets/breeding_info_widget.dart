import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_translations.dart';
import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../data/national_dex_data.dart';
import '../../../data/evolution_data.dart';
import 'pokemon_avatar.dart';

class BreedingInfoWidget extends StatelessWidget {
  final Pokemon pokemon;

  const BreedingInfoWidget({super.key, required this.pokemon});

  String _getPokeName(int id, String lang) {
    try {
      return nationalPokemonDatabase
          .firstWhere((p) => p.id == id)
          .getName(lang);
    } catch (_) {
      return '???';
    }
  }

  String _getGenderText(int rate) {
    if (rate == -1)
      return Translator.get('gender_genderless') != 'gender_genderless'
          ? Translator.get('gender_genderless')
          : 'Geschlechtslos';
    if (rate == 0) return '100% ♂';
    if (rate == 1) return '87.5% ♂ / 12.5% ♀';
    if (rate == 2) return '75% ♂ / 25% ♀';
    if (rate == 4) return '50% ♂ / 50% ♀';
    if (rate == 6) return '25% ♂ / 75% ♀';
    if (rate == 8) return '100% ♀';
    return Translator.get('unknown') != 'unknown'
        ? Translator.get('unknown')
        : 'Unbekannt';
  }

  Color _getGenderColor(int rate) {
    if (rate == -1) return Colors.grey;
    if (rate == 0) return Colors.blue;
    if (rate == 8) return Colors.pink;
    return Colors.purpleAccent;
  }

  IconData _getGenderIcon(int rate) {
    if (rate == -1) return Icons.transgender;
    if (rate == 0) return Icons.male;
    if (rate == 8) return Icons.female;
    return Icons.wc;
  }

  String _formatEvoDetails(Map<String, dynamic> detail) {
    if (detail.isEmpty)
      return Translator.get('evo_base_form') != 'evo_base_form'
          ? Translator.get('evo_base_form')
          : 'Basisform / Ei';

    String trigger = detail['trigger'] ?? '';
    List<String> conditions = [];

    if (detail['min_level'] != null)
      conditions.add(
        Translator.get(
          'evo_level',
        ).replaceAll('{0}', detail['min_level'].toString()),
      );
    if (detail['item'] != null)
      conditions.add(Translator.get('item_${detail['item']}'));
    if (detail['held_item'] != null)
      conditions.add(
        Translator.get(
          'evo_held_item',
        ).replaceAll('{0}', Translator.get('item_${detail['held_item']}')),
      );
    if (detail['min_happiness'] != null)
      conditions.add(Translator.get('evo_happiness'));
    if (detail['time_of_day'] != null &&
        detail['time_of_day'].toString().isNotEmpty) {
      conditions.add(Translator.get('evo_time_${detail['time_of_day']}'));
    }
    if (detail['known_move'] != null)
      conditions.add(
        Translator.get(
          'evo_move',
        ).replaceAll('{0}', Translator.get('move_${detail['known_move']}')),
      );
    if (detail['location'] != null)
      conditions.add(
        Translator.get(
          'evo_location',
        ).replaceAll('{0}', Translator.get('loc_${detail['location']}')),
      );

    String triggerText = Translator.get('trigger_$trigger');
    if (triggerText == 'trigger_$trigger') {
      if (trigger == 'level-up')
        triggerText = 'Levelaufstieg';
      else if (trigger == 'use-item')
        triggerText = 'Item anwenden';
      else if (trigger == 'trade')
        triggerText = 'Tausch';
      else
        triggerText = trigger;
    }

    if (conditions.isEmpty) return triggerText;
    return '$triggerText (${conditions.join(', ')})';
  }

  Widget _buildEvolutionNode(
    BuildContext context,
    Map<String, dynamic> node,
    int depth,
    String lang,
  ) {
    int speciesId = node['species_id'];
    List details = node['details'] ?? [];
    List evolvesTo = node['evolves_to'] ?? [];

    String conditionText = details.isEmpty
        ? (node['is_baby'] == true
              ? 'Baby-Pokémon'
              : (Translator.get('evo_base_form') != 'evo_base_form'
                    ? Translator.get('evo_base_form')
                    : 'Basisform / Ei'))
        : _formatEvoDetails(
            details.first,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (depth > 0)
                Padding(
                  padding: EdgeInsets.only(
                    left: (depth - 1) * 24.0,
                    right: 8.0,
                  ),
                  child: const Icon(
                    Icons.subdirectory_arrow_right,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              PokemonAvatar(
                id: speciesId,
                isShiny: false,
                gender: 'any',
                sizeScale: 0.7,
                isHighlight: speciesId == pokemon.id,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$speciesId ${_getPokeName(speciesId, lang)}',
                      style: TextStyle(
                        fontWeight: speciesId == pokemon.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      conditionText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (var childNode in evolvesTo)
          _buildEvolutionNode(context, childNode, depth + 1, lang),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final lang = provider.currentLanguage;

    String genderText = _getGenderText(pokemon.genderRate);
    IconData genderIcon = _getGenderIcon(pokemon.genderRate);
    Color genderColor = _getGenderColor(pokemon.genderRate);

    String eggGroupsText = Translator.get('unknown') != 'unknown'
        ? Translator.get('unknown')
        : 'Unbekannt';
    if (pokemon.eggGroups.isNotEmpty) {
      eggGroupsText = pokemon.eggGroups
          .map((g) {
            String tKey = 'egg_group_${g.toLowerCase().replaceAll('-', '')}';
            String t = Translator.get(tKey);
            return t == tKey ? g : t;
          })
          .join(', ');
    }

    Map<String, dynamic>? chainData;
    if (pokemon.evolutionChainId != -1) {
      chainData = evolutionDatabase[pokemon.evolutionChainId.toString()];
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.egg_alt, color: Colors.green),
        title: Text(
          Translator.get('breeding_info_title') != 'breeding_info_title'
              ? Translator.get('breeding_info_title')
              : 'Zucht und Entwicklung',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context,
                  Icons.catching_pokemon,
                  Translator.get('egg_groups') != 'egg_groups'
                      ? Translator.get('egg_groups')
                      : 'Ei-Gruppen',
                  eggGroupsText,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  genderIcon,
                  Translator.get('gender_ratio') != 'gender_ratio'
                      ? Translator.get('gender_ratio')
                      : 'Geschlechter',
                  genderText,
                  iconColor: genderColor,
                ),

                if (chainData != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1),
                  ),
                  _buildEvolutionNode(context, chainData, 0, lang),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
