import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/pokemon.dart';
import '../../../providers/dex_provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../utils/shiny_logic_helper.dart';

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
    final liveDex = provider.userDexes.firstWhere((d) => d.id == dexId);
    final caughtTeras = liveDex.caughtTeraTypes[entry.uniqueId] ?? [];

    String formName = entry.uniqueId.contains('_')
        ? entry.uniqueId.split('_').last
        : 'normal';
    if (formName == 'm' || formName == 'f') formName = 'normal';

    PokemonForm currentForm = entry.pokemon.forms.firstWhere(
      (f) => f.name == formName,
      orElse: () => entry.pokemon.forms.first,
    );

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

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.diamond_outlined, color: Colors.cyan),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    Translator.get(
                      'tera_types_title',
                      fallback: 'Terakristallisierung',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
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
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayTypes.map((type) {
                    bool isCaught = caughtTeras.contains(type);
                    String iconUrl =
                        'https://www.serebii.net/pokedex-sv/type/tera/$type.png';

                    return FilterChip(
                      avatar: Image.network(
                        iconUrl,
                        width: 24,
                        height: 24,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.diamond, size: 16),
                      ),
                      label: Text(
                        Translator.get(
                          'type_$type',
                          fallback: type.toUpperCase(),
                        ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
