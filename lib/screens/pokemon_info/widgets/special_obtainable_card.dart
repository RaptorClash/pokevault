import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/settings_provider.dart';

class SpecialObtainableCard extends StatelessWidget {
  final String uniqueId;

  const SpecialObtainableCard({super.key, required this.uniqueId});

  @override
  Widget build(BuildContext context) {
    final matchRegex = RegExp(r'_special_(\d+)_').firstMatch(uniqueId);
    if (matchRegex == null) return const SizedBox.shrink();

    final int specialId = int.parse(matchRegex.group(1)!);

    final currentLang = context.read<SettingsProvider>().currentLanguage;
    final allPokemon = context.read<DexProvider>().allPokemon;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getSpecialObtainables(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final match = snapshot.data!
            .where((s) => s['id'] == specialId)
            .firstOrNull;
        if (match == null) return const SizedBox.shrink();

        final bool isN = match['is_n_pokemon'] == 1;
        final bool isTrade = match['obtain_type'] == 'trade';
        final int givenPokeId = match['given_pokemon_id'] ?? -1;
        final String notesStr = match['notes']?.toString().toLowerCase() ?? '';
        final bool isGuaranteedShiny =
            notesStr.contains('shiny') || notesStr.contains('schillernd');

        String requiredPokemonName = "";
        if (isTrade && givenPokeId != -1) {
          final reqPoke = allPokemon
              .where((p) => p.id == givenPokeId)
              .firstOrNull;
          if (reqPoke != null) {
            requiredPokemonName = reqPoke.getName(currentLang);
          }
        }

        String levelText = match['level'].toString();
        if (match['level'] == 0) {
          levelText = currentLang == 'de'
              ? 'Skaliert (Wie abgegebenes Pokémon)'
              : 'Scales (Same as traded Pokémon)';
        }

        String otName = match['ot_name']?.toString() ?? '';
        if (otName.toLowerCase() == 'spieler' || otName.isEmpty) {
          otName = currentLang == 'de' ? 'Eigener' : 'Yours';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isN
                  ? Colors.green
                  : (isTrade ? Colors.blue : Colors.orange),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isN
                          ? Icons.auto_awesome
                          : (isTrade ? Icons.sync_alt : Icons.redeem),
                      color: isN
                          ? Colors.green
                          : (isTrade ? Colors.blue : Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isN
                            ? "N's Pokémon"
                            : (isTrade
                                  ? (currentLang == 'de'
                                        ? 'In-Game Tausch'
                                        : 'In-Game Trade')
                                  : (currentLang == 'de'
                                        ? 'Geschenk'
                                        : 'Gift')),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isGuaranteedShiny)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Shiny',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(),

                if (isTrade && requiredPokemonName.isNotEmpty) ...[
                  _buildRow(
                    currentLang == 'de' ? 'Gefordert:' : 'Required:',
                    requiredPokemonName,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 4),
                ],

                _buildRow('Level:', levelText),
                _buildRow('Original Trainer (OT):', otName),

                if (match['nickname'].toString().isNotEmpty)
                  _buildRow(
                    currentLang == 'de' ? 'Spitzname:' : 'Nickname:',
                    match['nickname'],
                  ),

                _buildRow(
                  currentLang == 'de' ? 'Ort:' : 'Location:',
                  match['location'],
                ),
                _buildRow(
                  currentLang == 'de' ? 'Spiel:' : 'Game:',
                  match['game_version'],
                ),
                _buildRow(
                  'Item:',
                  match['item'].toString().isNotEmpty ? match['item'] : '—',
                ),

                if (isN) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentLang == 'de'
                                ? 'Besitzt 30 IS (IVs) auf allen Statuswerten.'
                                : 'Has 30 IVs in all stats.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (match['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match['notes'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
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
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isHighlight ? Colors.blue : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.blue : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
