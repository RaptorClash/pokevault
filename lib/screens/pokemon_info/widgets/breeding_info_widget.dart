import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/strings.g.dart';
import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/database_service.dart';
import '../../../utils/location_translator.dart';
import 'pokemon_avatar.dart';
import 'lazy_expansion_card.dart';

class BreedingInfoWidget extends StatelessWidget {
  final Pokemon pokemon;
  final PokemonForm? currentForm;

  const BreedingInfoWidget({
    super.key,
    required this.pokemon,
    this.currentForm,
  });

  static String _trans(String key, [String? fallback]) {
    final cleanKey = key.replaceAll('-', '_');
    final res = t[key] ?? t[cleanKey];
    if (res != null) return res.toString();
    final loc = LocationTranslator.translate(cleanKey);
    if (loc != cleanKey && loc != key) return loc;
    final locOrig = LocationTranslator.translate(key);
    if (locOrig != key) return locOrig;
    return (fallback ?? key).toString();
  }

  String _getPokeName(int id, String lang, DexProvider provider) {
    try {
      final p = provider.allPokemon.firstWhere((p) => p.id == id);
      return p.getName(lang);
    } catch (_) {
      return '???';
    }
  }

  String _getGenderText(int rate) {
    if (rate == -1) {
      return t.gender_genderless;
    }
    if (rate == 0) return '100% ♂';
    if (rate == 1) return '87.5% ♂ / 12.5% ♀';
    if (rate == 2) return '75% ♂ / 25% ♀';
    if (rate == 4) return '50% ♂ / 50% ♀';
    if (rate == 6) return '25% ♂ / 75% ♀';
    if (rate == 8) return '100% ♀';
    return t.unknown;
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

  String _formatEvoDetails(List details) {
    if (details.isEmpty) {
      return t.evo_base_form;
    }

    const magneticLocations = {
      'mt-coronet',
      'chargestone-cave',
      'kalos-route-13',
      'blush-mountain',
      'vast-poni-canyon',
      'new-mauville',
    };

    List<String> allMethods = [];

    for (var detail in details) {
      String trigger = detail['trigger']?.toString() ?? '';
      List<String> conditions = [];

      // Geschlecht (1 = female, 2 = male)
      if (detail['gender'] == 1) {
        conditions.add(t.evo_gender_female);
      } else if (detail['gender'] == 2) {
        conditions.add(t.evo_gender_male);
      }

      // Tageszeit
      if (detail['time_of_day'] != null &&
          detail['time_of_day'].toString().isNotEmpty) {
        String tod = detail['time_of_day'].toString();
        conditions.add(_trans('evo_time_$tod', tod));
      }

      // Getragenes Item
      if (detail['held_item'] != null) {
        String itemKey = 'item_${detail['held_item']}';
        String itemName = _trans(itemKey);
        conditions.add(
          t.evo_held_item
              .replaceAll('{0}', itemName),
        );
      }

      // Attacke
      if (detail['known_move'] != null) {
        String moveKey = 'move_${detail['known_move']}';
        String moveName = _trans(moveKey);
        conditions.add(
          t.evo_move
              .replaceAll('{0}', moveName),
        );
      }
      if (detail['known_move_type'] != null) {
        String typeKey = 'type_${detail['known_move_type']}';
        String typeName = _trans(typeKey, detail['known_move_type'].toString());
        conditions.add(
          t.evo_move_type
              .replaceAll('{0}', typeName),
        );
      }
      if (detail['used_move'] != null) {
        String moveKey = 'move_${detail['used_move']}';
        String moveName = _trans(moveKey);
        if (detail['min_move_count'] != null) {
          conditions.add(
            '$moveName, ${t.evo_move_count.replaceAll('{0}', detail['min_move_count'].toString())}',
          );
        } else {
          conditions.add(moveName);
        }
      }

      // Ort & Felsen & Magnetfeld
      if (detail['near_special_rock'] == true) {
        conditions.add(
          t.evo_special_rock,
        );
      } else if (detail['location'] != null) {
        String loc = detail['location'].toString();
        if (magneticLocations.contains(loc)) {
          conditions.add(
            t.evo_magnetic_field,
          );
        } else {
          String locKey = 'loc_$loc';
          String locName = _trans(locKey, loc);
          conditions.add(
            t.evo_location
                .replaceAll('{0}', locName),
          );
        }
      }

      // Statuswerte (z.B. Rabauz -> Kicklee/Nockchan/Kapoera)
      if (detail['relative_physical_stats'] != null) {
        int rel = (detail['relative_physical_stats'] as num).toInt();
        if (rel == 1) {
          conditions.add(t.evo_stat_atk_gt_def);
        } else if (rel == -1) {
          conditions.add(t.evo_stat_atk_lt_def);
        } else {
          conditions.add(t.evo_stat_atk_eq_def);
        }
      }

      // Schönheit (Barschwa -> Milotic)
      if (detail['min_beauty'] != null) {
        String bty = t.evo_beauty
            .replaceAll('{0}', detail['min_beauty'].toString());
        conditions.add(bty);
      }

      // Spezielle Spielmechaniken
      if (detail['needs_overworld_rain'] == true) {
        conditions.add(t.evo_rain);
      }
      if (detail['turn_upside_down'] == true) {
        conditions.add(t.evo_upside_down);
      }
      if (detail['needs_multiplayer'] == true) {
        conditions.add(t.evo_multiplayer);
      }
      if (detail['min_steps'] != null) {
        conditions.add(
          t.evo_steps
              .replaceAll('{0}', detail['min_steps'].toString()),
        );
      }
      if (detail['min_damage_taken'] != null) {
        conditions.add(
          t.evo_damage
              .replaceAll('{0}', detail['min_damage_taken'].toString()),
        );
      }
      if (detail['party_species'] != null) {
        String species = detail['party_species'].toString();
        String speciesKey = 'species_$species';
        String fallbackSpecies = species.isNotEmpty
            ? species[0].toUpperCase() + species.substring(1)
            : species;
        String speciesName = _trans(speciesKey, fallbackSpecies);
        conditions.add(
          t.evo_party_species
              .replaceAll('{0}', speciesName),
        );
      }
      if (detail['party_type'] != null) {
        String typeKey = 'type_${detail['party_type']}';
        String typeName = _trans(typeKey, detail['party_type'].toString());
        conditions.add(
          t.evo_party_type
              .replaceAll('{0}', typeName),
        );
      }
      if (detail['trade_species'] != null) {
        String species = detail['trade_species'].toString();
        String speciesKey = 'species_$species';
        String fallbackSpecies = species.isNotEmpty
            ? species[0].toUpperCase() + species.substring(1)
            : species;
        String speciesName = _trans(speciesKey, fallbackSpecies);
        conditions.add(
          t.evo_trade_species
              .replaceAll('{0}', speciesName),
        );
      }

      // Hauptdarstellung je nach Auslöser (Trigger)
      if (trigger == 'use-item' && detail['item'] != null) {
        String itemKey = 'item_${detail['item']}';
        String itemName = _trans(itemKey);
        if (conditions.isEmpty) {
          allMethods.add(itemName);
        } else {
          allMethods.add('$itemName (${conditions.join(', ')})');
        }
      } else if (trigger == 'level-up') {
        if (detail['min_level'] != null) {
          String lvlText = t.evo_level
              .replaceAll('{0}', detail['min_level'].toString());
          if (conditions.isEmpty) {
            allMethods.add(lvlText);
          } else {
            allMethods.add('$lvlText (${conditions.join(', ')})');
          }
        } else if (detail['min_happiness'] != null) {
          String hap = t.evo_happiness;
          if (hap.isNotEmpty) {
            hap = hap[0].toUpperCase() + hap.substring(1);
          }
          if (conditions.isEmpty) {
            allMethods.add(hap);
          } else {
            allMethods.add('$hap (${conditions.join(', ')})');
          }
        } else if (detail['min_affection'] != null) {
          String aff = t.evo_affection;
          if (aff.isNotEmpty) {
            aff = aff[0].toUpperCase() + aff.substring(1);
          }
          if (conditions.isEmpty) {
            allMethods.add(aff);
          } else {
            allMethods.add('$aff (${conditions.join(', ')})');
          }
        } else if (conditions.isNotEmpty) {
          String trText = t.trigger_level_up;
          allMethods.add('$trText (${conditions.join(', ')})');
        } else {
          allMethods.add(t.trigger_level_up);
        }
      } else if (trigger == 'trade') {
        String trText = t.trigger_trade;
        if (conditions.isEmpty) {
          allMethods.add(trText);
        } else {
          allMethods.add('$trText (${conditions.join(', ')})');
        }
      } else {
        String trText = _trans('trigger_$trigger', trigger);
        if (detail['min_level'] != null) {
          String lvlText = t.evo_level
              .replaceAll('{0}', detail['min_level'].toString());
          if (conditions.isEmpty) {
            allMethods.add('$lvlText ($trText)');
          } else {
            allMethods.add('$lvlText ($trText, ${conditions.join(', ')})');
          }
        } else if (conditions.isEmpty) {
          allMethods.add(trText);
        } else {
          allMethods.add('$trText (${conditions.join(', ')})');
        }
      }
    }

    final seen = <String>{};
    final unique = <String>[];
    for (var m in allMethods) {
      if (seen.add(m)) {
        unique.add(m);
      }
    }

    return unique.isEmpty
        ? t.evo_base_form
        : unique.join(' / ');
  }

  String? _getRegionalTag(String formName) {
    final lower = formName.toLowerCase();
    for (final tag in ['alola', 'galar', 'hisui', 'paldea']) {
      if (lower.contains(tag)) return tag;
    }
    return null;
  }

  String? _getDetailRegionalForm(Map<dynamic, dynamic> detail) {
    final ef = detail['evolved_form']?.toString().toLowerCase();
    final bf = detail['base_form']?.toString().toLowerCase();
    final rg = detail['region']?.toString().toLowerCase();

    for (final tag in ['alola', 'galar', 'hisui', 'paldea']) {
      if ((ef != null && ef.contains(tag)) ||
          (bf != null && bf.contains(tag)) ||
          (rg != null && rg.contains(tag))) {
        return tag;
      }
    }
    return null;
  }

  String _determineEffectiveForm(Map<String, dynamic> chainData) {
    if (currentForm != null) {
      final reg = _getRegionalTag(currentForm!.name);
      if (reg != null) return reg;
      if (currentForm!.name.isNotEmpty && currentForm!.name != 'normal') {
        return currentForm!.name.toLowerCase();
      }
    }

    String? foundForm;
    void searchNode(Map<String, dynamic> node) {
      if (foundForm != null) return;
      for (final child in node['evolves_to'] ?? []) {
        if (child is Map<String, dynamic>) {
          if (child['species_id'] == pokemon.id) {
            final details = (child['details'] as List?) ?? [];
            if (details.isNotEmpty &&
                details.every(
                  (d) => d is Map && _getDetailRegionalForm(d) != null,
                )) {
              foundForm = _getDetailRegionalForm(details.first as Map);
              return;
            }
          }
          searchNode(child);
        }
      }
    }

    searchNode(chainData);
    return foundForm ?? 'normal';
  }

  bool _nodeMatchesForm(Map<String, dynamic> childNode, String formName) {
    final childDetails = (childNode['details'] as List?) ?? [];
    if (childDetails.isEmpty) return true;

    final isRegional = ['alola', 'galar', 'hisui', 'paldea'].contains(formName);

    if (isRegional) {
      return childDetails.any((d) => _getDetailRegionalForm(d) == formName);
    } else {
      return childDetails.any((d) => _getDetailRegionalForm(d) == null);
    }
  }

  List _filterDetails(List rawDetails, String formName) {
    if (rawDetails.isEmpty) return rawDetails;
    final isRegional = ['alola', 'galar', 'hisui', 'paldea'].contains(formName);

    if (isRegional) {
      final matching = rawDetails.where((d) => _getDetailRegionalForm(d) == formName).toList();
      if (matching.isNotEmpty) return matching;

      return rawDetails.where((d) => _getDetailRegionalForm(d) == null).toList();
    } else {
      final normalOnly = rawDetails.where((d) => _getDetailRegionalForm(d) == null).toList();
      return normalOnly.isNotEmpty ? normalOnly : rawDetails;
    }
  }

  Widget _buildEvolutionNode(
    BuildContext context,
    Map<String, dynamic> node,
    int depth,
    String lang,
    DexProvider provider,
    String effectiveForm,
  ) {
    int speciesId = node['species_id'];
    List details = node['details'] ?? [];
    List evolvesTo = node['evolves_to'] ?? [];

    final filteredDetails = _filterDetails(details, effectiveForm);
    final filteredEvolvesTo = evolvesTo.where((child) {
      if (child is Map<String, dynamic>) {
        return _nodeMatchesForm(child, effectiveForm);
      }
      return true;
    }).toList();

    int? targetImageId;
    if (speciesId == pokemon.id && currentForm != null && currentForm!.imageId > 0) {
      targetImageId = currentForm!.imageId;
    } else if (effectiveForm != 'normal') {
      final nodePoke = provider.allPokemon.where((poke) => poke.id == speciesId).firstOrNull;
      if (nodePoke != null) {
        final matchedForm = nodePoke.forms.where(
          (f) => _getRegionalTag(f.name) == effectiveForm || f.name.toLowerCase() == effectiveForm,
        ).firstOrNull;
        if (matchedForm != null && matchedForm.imageId > 0) {
          targetImageId = matchedForm.imageId;
        }
      }
    }

    String conditionText = filteredDetails.isEmpty
        ? (node['is_baby'] == true
              ? t.evo_baby
              : (t.evo_base_form))
        : _formatEvoDetails(filteredDetails);

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
                imageId: targetImageId,
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
                      '#$speciesId ${_getPokeName(speciesId, lang, provider)}',
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
        for (var childNode in filteredEvolvesTo)
          _buildEvolutionNode(
            context,
            childNode,
            depth + 1,
            lang,
            provider,
            effectiveForm,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final lang = settingsProvider.currentLanguage;

    String genderText = _getGenderText(pokemon.genderRate);
    IconData genderIcon = _getGenderIcon(pokemon.genderRate);
    Color genderColor = _getGenderColor(pokemon.genderRate);

    String eggGroupsText = t.unknown;
    if (pokemon.eggGroups.isNotEmpty) {
      eggGroupsText = pokemon.eggGroups
          .map((g) {
            String tKey = 'egg_group_${g.toLowerCase().replaceAll('-', '')}';
            String translatedGroup = (t[tKey] ?? tKey).toString();
            return translatedGroup == tKey ? g : translatedGroup;
          })
          .join(', ');
    }

    return LazyExpansionCard(
      leading: const Icon(Icons.egg_alt, color: Colors.green),
      title: Text(
        t.breeding_info_title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      builder: (context) {
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  t.egg_groups,
                  eggGroupsText,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  genderIcon,
                  t.gender_ratio,
                  genderText,
                  iconColor: genderColor,
                ),
                if (pokemon.eggGroups.any(
                  (g) =>
                      g.toLowerCase().contains('no eggs') ||
                      g.toLowerCase().contains('undiscovered'),
                )) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleSettings.currentLocale == AppLocale.de
                                ? 'Pokémon dieser Ei-Gruppe können keine Eier legen. Handelt es sich um ein Baby-Pokémon, muss es zur Zucht erst entwickelt werden.'
                                : 'Pokémon in this egg group cannot produce eggs. If this is a Baby Pokémon, you must evolve it first.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (pokemon.evolutionChainId != -1)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: DatabaseService.instance.getEvolutionChain(
                      pokemon.evolutionChainId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1),
                            ),
                            Builder(
                              builder: (context) {
                                final effectiveForm =
                                    _determineEffectiveForm(snapshot.data!);
                                return _buildEvolutionNode(
                                  context,
                                  snapshot.data!,
                                  0,
                                  lang,
                                  provider,
                                  effectiveForm,
                                );
                              },
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          );
        },
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
