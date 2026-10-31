import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/pokemon.dart';
import '../../../models/user_dex.dart';
import '../../../providers/dex_provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/shiny_logic_helper.dart';
import '../../../widgets/universal_poke_image.dart';
import 'lazy_expansion_card.dart';

class TeraTypeWidget extends StatelessWidget {
  final DexDisplayEntry entry;
  final String dexId;

  static const List<String> _allTypes = [
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
    'stellar',
  ];

  const TeraTypeWidget({super.key, required this.entry, required this.dexId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere(
      (d) => d.id == dexId,
      orElse: () => UserDex.fallback(dexId),
    );
    final caughtTeras = liveDex.caughtTeraTypes[entry.uniqueId] ?? [];

    if (entry.pokemon.forms.isEmpty) {
      return const SizedBox.shrink();
    }

    PokemonForm currentForm = entry.resolvedForm ?? entry.pokemon.forms.first;

    return FutureBuilder<Map<String, dynamic>>(
      future: ShinyLogicHelper.fetchGen9Data(entry.pokemon.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        bool isSV = snapshot.data!['isSV'] == true;
        if (!isSV) return const SizedBox.shrink();

        List<String> displayTypes = currentForm.forcedTeraType != null
            ? [currentForm.forcedTeraType!]
            : _allTypes;

        int earnedCount = displayTypes
            .where((t) => caughtTeras.contains(t))
            .length;

        return LazyExpansionCard(
          leading: const Icon(Icons.diamond_outlined, color: Colors.cyan),
          title: Text(
            t.tera_types_title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$earnedCount / ${displayTypes.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayTypes.map((type) {
                  bool isCaught = caughtTeras.contains(type);
                  String iconUrl =
                      'https://www.serebii.net/pokedex-sv/type/tera/$type.png';

                  return FilterChip(
                    avatar: UniversalPokeImage(
                      imageUrl: iconUrl,
                      width: 24,
                      height: 24,
                      cacheWidth: 48,
                      cacheHeight: 48,
                      errorIconSize: 16,
                    ),
                    label: Text(
                      (t['type_$type'] ?? type.toUpperCase()),
                      style: TextStyle(
                        color: isCaught ? Colors.green : null,
                        fontWeight: isCaught
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isCaught,
                    selectedColor: Colors.green.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isCaught ? Colors.green : Colors.transparent,
                      width: 1.5,
                    ),
                    showCheckmark: false,
                    onSelected: (_) {
                      provider.toggleTeraType(dexId, entry.uniqueId, type);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
