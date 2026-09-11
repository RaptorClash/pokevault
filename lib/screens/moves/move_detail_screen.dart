import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
import '../../models/special_dex_models.dart';
import '../../providers/dex_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/universal_poke_image.dart';

class MoveDetailScreen extends StatefulWidget {
  final PokeMove move;
  const MoveDetailScreen({super.key, required this.move});

  @override
  State<MoveDetailScreen> createState() => _MoveDetailScreenState();
}

class _MoveDetailScreenState extends State<MoveDetailScreen> {
  String _searchQuery = '';
  late Future<List<PokemonLearnset>> _learnsetsFuture;

  @override
  void initState() {
    super.initState();
    _learnsetsFuture = DatabaseService.instance.getPokemonForMove(
      widget.move.id,
    );
  }

  String _formatLearnMethod(String method, int level) {
    switch (method) {
      case 'level-up':
        return 'Lv. $level';
      case 'machine':
        return 'TM/TR';
      case 'egg':
        return 'Ei';
      case 'tutor':
        return 'Lehrer';
      default:
        return method;
    }
  }

  String _translateVersionGroup(String vg) {
    final map = {
      'red-blue': 'Rot & Blau',
      'yellow': 'Gelb',
      'gold-silver': 'Gold & Silber',
      'crystal': 'Kristall',
      'ruby-sapphire': 'Rubin & Saphir',
      'emerald': 'Smaragd',
      'firered-leafgreen': 'Feuerrot & Blattgrün',
      'diamond-pearl': 'Diamant & Perl',
      'platinum': 'Platin',
      'heartgold-soulsilver': 'HeartGold & SoulSilver',
      'black-white': 'Schwarz & Weiß',
      'black-2-white-2': 'Schwarz 2 & Weiß 2',
      'x-y': 'X & Y',
      'omega-ruby-alpha-sapphire': 'Omega Rubin & Alpha Saphir',
      'sun-moon': 'Sonne & Mond',
      'ultra-sun-ultra-moon': 'Ultra-Sonne & Ultra-Mond',
      'lets-go-pikachu-lets-go-eevee': 'Let\'s Go Pikachu & Evoli',
      'sword-shield': 'Schwert & Schild',
      'brilliant-diamond-shining-pearl':
          'Strahlender Diamant & Leuchtende Perle',
      'legends-arceus': 'Legenden: Arceus',
      'scarlet-violet': 'Karmesin & Purpur',
    };
    return map[vg] ?? vg.toUpperCase().replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final lang = Translator.currentLanguage;
    final provider = context.watch<DexProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.move.getName(lang))),
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

          Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var item in resolvedLearnsets) {
            final l = item['learnset'] as PokemonLearnset;
            grouped.putIfAbsent(l.versionGroup, () => []).add(item);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${Translator.get('type')}: ${Translator.get('type_${widget.move.type.toLowerCase()}', fallback: widget.move.type.toUpperCase())}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${Translator.get('category')}: ${Translator.get('category_${widget.move.damageClass.toLowerCase()}', fallback: widget.move.damageClass.toUpperCase())}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${Translator.get('power_short', fallback: 'Stärke')}: ${widget.move.power > 0 ? widget.move.power : '-'}',
                              ),
                              Text(
                                '${Translator.get('accuracy_short', fallback: 'Genauigk.')}: ${widget.move.accuracy > 0 ? widget.move.accuracy : '-'}',
                              ),
                              Text('AP: ${widget.move.pp}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.move.getDesc(lang),
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
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
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final version = grouped.keys.elementAt(index);
                  final items = grouped[version]!;
                  final versionName = _translateVersionGroup(version);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.2),
                    child: ExpansionTile(
                      title: Text(
                        versionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 100,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final learnset =
                                item['learnset'] as PokemonLearnset;

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
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
                                    const SizedBox(height: 4),
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
                                    Text(
                                      _formatLearnMethod(
                                        learnset.learnMethod,
                                        learnset.levelLearned,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }, childCount: grouped.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
