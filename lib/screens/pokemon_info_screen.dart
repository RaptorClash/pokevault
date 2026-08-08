import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import 'dex_screen.dart';

class PokemonInfoScreen extends StatelessWidget {
  final DexDisplayEntry entry;
  final String dexId;

  const PokemonInfoScreen({
    super.key,
    required this.entry,
    required this.dexId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere((d) => d.id == dexId);
    
    final isCaught = liveDex.caughtIds.contains(entry.uniqueId);
    final isShiny = liveDex.shinyIds.contains(entry.uniqueId);

    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.get('extra_info') != 'extra_info' ? Translator.get('extra_info') : 'Zusatzinformationen'),
        leading: const CloseButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ColorFiltered(
                colorFilter: isCaught
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                child: Image.network(
                  entry.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${entry.pokemon.id}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.catching_pokemon, size: 60),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              '#${entry.pokemon.id.toString().padLeft(3, '0')}',
              style: TextStyle(fontSize: 20, color: Theme.of(context).hintColor, fontWeight: FontWeight.bold),
            ),
            Text(
              entry.pokemon.getName(provider.currentLanguage),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (entry.displaySuffix.trim().isNotEmpty)
              Text(
                '${Translator.get('form') != 'form' ? Translator.get('form') : 'Form'}: ${entry.displaySuffix.replaceAll('(', '').replaceAll(')', '').trim()}',
                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            
            const SizedBox(height: 32),

            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: SwitchListTile(
                title: const Text('Shiny Status', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Als schillernd markieren'),
                secondary: Icon(Icons.star, color: isShiny ? Colors.amber : Colors.grey),
                value: isShiny,
                activeColor: Colors.amber,
                onChanged: (val) {
                  provider.toggleShiny(dexId, entry.uniqueId);
                },
              ),
            ),

            const SizedBox(height: 16),

            _buildPlaceholderCard(context, Icons.videogame_asset, Translator.get('games_appearance') != 'games_appearance' ? Translator.get('games_appearance') : 'Kommt vor in'),
            _buildPlaceholderCard(context, Icons.catching_pokemon, Translator.get('games_catchable') != 'games_catchable' ? Translator.get('games_catchable') : 'Fangbar in'),
            _buildPlaceholderCard(context, Icons.celebration, Translator.get('events') != 'events' ? Translator.get('events') : 'Event-Verteilungen'),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(Translator.get('ignore_pokemon') != 'ignore_pokemon' ? Translator.get('ignore_pokemon') : 'Aus Dex entfernen'),
                onPressed: () {
                  _confirmIgnore(context, provider);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(Translator.get('placeholder_text') != 'placeholder_text' ? Translator.get('placeholder_text') : 'Wird in zukünftigen Updates hinzugefügt.'),
      ),
    );
  }

  void _confirmIgnore(BuildContext context, DexProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translator.get('ignore_confirm_title') != 'ignore_confirm_title' ? Translator.get('ignore_confirm_title') : 'Pokémon entfernen?'),
        content: Text(Translator.get('ignore_confirm_text') != 'ignore_confirm_text' ? Translator.get('ignore_confirm_text') : 'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translator.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              provider.ignorePokemon(dexId, entry.uniqueId);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: Text(Translator.get('ignore_pokemon') != 'ignore_pokemon' ? Translator.get('ignore_pokemon') : 'Entfernen'),
          ),
        ],
      ),
    );
  }
}