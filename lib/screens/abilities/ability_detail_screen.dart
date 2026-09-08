import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../models/special_dex_models.dart';
import '../../providers/dex_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/universal_poke_image.dart';

class AbilityDetailScreen extends StatefulWidget {
  final PokeAbility ability;
  const AbilityDetailScreen({super.key, required this.ability});

  @override
  State<AbilityDetailScreen> createState() => _AbilityDetailScreenState();
}

class _AbilityDetailScreenState extends State<AbilityDetailScreen> {
  String _searchQuery = '';
  late Future<List<PokemonLearnset>> _learnsetsFuture;

  @override
  void initState() {
    super.initState();
    _learnsetsFuture = DatabaseService.instance.getPokemonForAbility(
      widget.ability.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Translator.currentLanguage;
    final provider = context.watch<DexProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.ability.getName(lang))),
      body: FutureBuilder<List<PokemonLearnset>>(
        future: _learnsetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLearnsets = snapshot.data ?? [];
          List<Map<String, dynamic>> resolvedLearnsets = [];

          for (var l in allLearnsets) {
            String pokeName = 'Pokémon #${l.pokemonId}';
            String imageUrl =
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${l.pokemonId}.png';

            for (var p in provider.allPokemon) {
              if (p.id == l.pokemonId) {
                pokeName = p.getName(lang);
                break;
              }
              bool foundForm = false;
              for (var f in p.forms) {
                if (f.imageId == l.pokemonId) {
                  pokeName = '${p.getName(lang)} (${f.name.toUpperCase()})';
                  foundForm = true;
                  break;
                }
              }
              if (foundForm) break;
            }

            if (_searchQuery.isEmpty ||
                pokeName.toLowerCase().contains(_searchQuery.toLowerCase())) {
              resolvedLearnsets.add({
                'learnset': l,
                'name': pokeName,
                'image': imageUrl,
              });
            }
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.ability.getDesc(lang),
                        style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Pokémon suchen...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 110,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = resolvedLearnsets[index];
                    final learnset = item['learnset'] as PokemonLearnset;

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: learnset.isHiddenAbility
                              ? Colors.amber.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: UniversalPokeImage(
                                imageUrl: item['image'],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: learnset.isHiddenAbility
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                learnset.isHiddenAbility
                                    ? Translator.get(
                                        'hidden_ability_short',
                                        fallback: 'Versteckt',
                                      )
                                    : Translator.get(
                                        'normal_ability_short',
                                        fallback: 'Normal',
                                      ),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: learnset.isHiddenAbility
                                      ? Colors.amber.shade700
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: learnset.isHiddenAbility
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: resolvedLearnsets.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
