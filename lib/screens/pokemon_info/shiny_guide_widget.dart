import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/dex_view_models.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../utils/shiny_logic_helper.dart';
import '../../services/database_service.dart';
import '../../services/shiny_lock_service.dart';
import '../../utils/dex_logic_helper.dart';
import './shiny_guides/gen1_shiny_guide.dart';
import './shiny_guides/gen2_shiny_guide.dart';
import './shiny_guides/gen3_shiny_guide.dart';
import './shiny_guides/gen4_shiny_guide.dart';
import './shiny_guides/gen5_shiny_guide.dart';
import './shiny_guides/gen6_shiny_guide.dart';
import './shiny_guides/gen7_shiny_guide.dart';
import './shiny_guides/gen7_5_shiny_guide.dart';
import './shiny_guides/gen8_shiny_guide.dart';
import './shiny_guides/gen8_5_shiny_guide.dart';
import './shiny_guides/gen9_shiny_guide.dart';
import './shiny_guides/gen9_5_shiny_guide.dart';
import '../../models/shiny_hunt.dart';
import '../shiny_hunt/dialogs/create_edit_hunt_dialog.dart';
import '../shiny_hunt/shiny_hunt_counter_screen.dart';

class ShinyGuideWidget extends StatefulWidget {
  final DexDisplayEntry entry;
  final String dexId;

  const ShinyGuideWidget({super.key, required this.entry, required this.dexId});

  @override
  State<ShinyGuideWidget> createState() => _ShinyGuideWidgetState();
}

class _ShinyGuideWidgetState extends State<ShinyGuideWidget> {
  late int _selectedLevel;
  List<String> _shinyCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final id = widget.entry.pokemon.id;
      final level = await DatabaseService.instance.getDefaultLevel(id);
      final categories = await DatabaseService.instance.getShinyCategories(id);

      if (mounted) {
        setState(() {
          _selectedLevel = level;
          _shinyCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fehler beim Laden der Shiny-Daten: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationHelper.showError('Fehler beim Laden der Shiny-Daten: $e');
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          NotificationHelper.showError(
            '${Translator.get('error_launch_url')} $urlString',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          '${Translator.get('error_launch_url')} $e',
        );
      }
    }
  }

  Widget _buildStartHuntButton(
    BuildContext context,
    double gen, {
    String? method,
    double? baseOdds,
    int? spawns,
    String? game,
    String? buttonLabel,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.track_changes, color: Colors.amber),
        label: Text(
          buttonLabel ?? Translator.get('shiny_hunt_start_from_guide', fallback: '🎯 Hunt starten'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.amber),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () async {
          final createdHunt = await showDialog<ShinyHunt?>(
            context: context,
            builder: (ctx) => CreateEditHuntDialog(
              initialPokemonId: widget.entry.pokemon.id,
              initialPokemonName: widget.entry.pokemon.nameDe,
              initialFormId: (widget.entry.resolvedForm?.imageId != null && widget.entry.resolvedForm!.imageId > 0)
                  ? widget.entry.resolvedForm!.imageId
                  : widget.entry.pokemon.id,
              initialDexId: widget.dexId,
              initialUniqueId: widget.entry.uniqueId,
              initialGeneration: gen,
              initialMethod: method,
              initialBaseOdds: baseOdds,
              initialSpawns: spawns,
              initialGame: game,
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
    );
  }

  bool _shouldShowGen(double gen) {
    if (ShinyLogicHelper.isAnyCapPikachu(widget.entry)) {
      return gen == 7.0;
    }
    if (widget.entry.uniqueId.contains('vc_glitch') ||
        (widget.entry.resolvedForm?.name == 'vc_glitch')) {
      return gen == 2.0;
    }
    if (ShinyLockService.isNPokemon(widget.entry)) {
      return gen == 5.0;
    }
    final originGen = DexLogicHelper.getOriginGeneration(widget.entry.uniqueId);
    if (originGen != null && gen < originGen) {
      return false;
    }
    if (gen == 2 &&
        widget.entry.pokemon.id >= 252 &&
        widget.entry.pokemon.id <= 257) {
      return true;
    }
    if (gen == 1) return widget.entry.pokemon.id <= 151;
    if (gen == 2) return widget.entry.pokemon.id <= 251;
    if (gen == 3) return widget.entry.pokemon.id <= 386;
    if (gen == 4) return widget.entry.pokemon.id <= 493;
    if (gen == 5) return widget.entry.pokemon.id <= 649;
    if (gen == 6) return widget.entry.pokemon.id <= 721;
    if (gen == 7) return widget.entry.pokemon.id <= 807;
    if (gen == 7.5) {
      return widget.entry.pokemon.id <= 151 ||
          widget.entry.pokemon.id == 808 ||
          widget.entry.pokemon.id == 809;
    }
    if (gen == 8) return widget.entry.pokemon.id <= 905;
    if (gen == 8.5) return widget.entry.pokemon.id <= 905;
    if (gen == 9) return widget.entry.pokemon.id <= 1025;
    if (gen == 9.5) return widget.entry.pokemon.id <= 1025;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    const List<double> generations = [
      1.0,
      2.0,
      3.0,
      4.0,
      5.0,
      6.0,
      7.0,
      7.5,
      8.0,
      8.5,
      9.0,
      9.5,
    ];

    final isLocked = ShinyLockService.isShinyLocked(widget.entry);
    if (!isLocked && !generations.any(_shouldShowGen)) return const SizedBox.shrink();

    List<Widget> genTiles = [];

    for (double gen in generations) {
      if (_shouldShowGen(gen)) {
        String titleKey;
        String fallbackTitle;
        if (gen == 7.5) {
          titleKey = 'shiny_guide_gen7_5';
          fallbackTitle = 'Generation 7.5';
        } else if (gen == 8.5) {
          titleKey = 'shiny_guide_gen8_5';
          fallbackTitle = 'Generation 8.5';
        } else if (gen == 9.5) {
          titleKey = 'shiny_guide_gen9_5';
          fallbackTitle = 'Generation 9.5';
        } else {
          titleKey = 'shiny_guide_gen${gen.toInt()}';
          fallbackTitle = 'Generation ${gen.toInt()}';
        }

        String resolvedTitle = Translator.get(titleKey) != titleKey
            ? Translator.get(titleKey)
            : fallbackTitle;

        if (gen == 1.0) {
          final isTowerGhost = [92, 93, 104, 105].contains(widget.entry.pokemon.id);
          List<Widget> gen1Actions = [];
          if (isTowerGhost) {
            gen1Actions.add(_buildStartHuntButton(
              context,
              1.0,
              method: 'Pokémon-Turm / Silph Scope',
              baseOdds: 8192.0,
              game: 'Rot / Blau / Gelb',
              buttonLabel: Translator.get('shiny_hunt_start_silph_scope'),
            ));
            gen1Actions.add(const SizedBox(height: 8));
          }
          gen1Actions.add(_buildStartHuntButton(
            context,
            1.0,
            game: 'Rot / Blau / Gelb',
          ));

          genTiles.add(
            ExpansionTile(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Gen1ShinyGuide(
                    pokemon: widget.entry.pokemon,
                    shinyCategories: _shinyCategories,
                    initialLevel: _selectedLevel,
                    onLaunchUrl: _launchURL,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(children: gen1Actions),
                ),
              ],
            ),
          );
        } else if (gen == 2.0) {
          final isBaby = widget.entry.pokemon.id <= 251 && ShinyLogicHelper.isBaby(widget.entry.pokemon.id);
          final isBreedable = widget.entry.pokemon.id <= 251 &&
              (ShinyLogicHelper.isBreedable(widget.entry.pokemon) || ShinyLogicHelper.isBaby(widget.entry.pokemon.id));
          List<Widget> gen2Actions = [];
          if (isBaby) {
            gen2Actions.add(_buildStartHuntButton(
              context,
              2.0,
              method: 'Kurioses Ei / Odd Egg (Kristall)',
              baseOdds: 100.0 / 14.0,
              buttonLabel: Translator.get('shiny_hunt_start_odd_egg'),
            ));
            gen2Actions.add(const SizedBox(height: 8));
          }
          if (isBreedable) {
            gen2Actions.add(_buildStartHuntButton(
              context,
              2.0,
              method: 'Shiny-Zucht / Ditto-Glitch',
              baseOdds: 64.0,
              buttonLabel: Translator.get('shiny_hunt_start_ditto_glitch'),
            ));
            gen2Actions.add(const SizedBox(height: 8));
          }
          gen2Actions.add(_buildStartHuntButton(context, 2.0));

          genTiles.add(
            ExpansionTile(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Gen2ShinyGuide(
                    pokemon: widget.entry.pokemon,
                    dexId: widget.dexId,
                    onLaunchUrl: _launchURL,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(children: gen2Actions),
                ),
              ],
            ),
          );
        } else if (gen == 3.0) {
          genTiles.add(
            ExpansionTile(
              title: Text(
                resolvedTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Gen3ShinyGuide(onLaunchUrl: _launchURL),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildStartHuntButton(context, 3.0),
                ),
              ],
            ),
          );
        } else if (gen == 4.0) {
          final id = widget.entry.pokemon.id;
          final isHgssStarter = id == 152 || id == 155 || id == 158;
          final hasGenderVariation = widget.entry.pokemon.genderRate > 0 &&
              widget.entry.pokemon.genderRate < 8 &&
              !_shinyCategories.contains('legendary_mythical');

          List<Widget> gen4Actions = [];
          if (isHgssStarter) {
            gen4Actions.add(_buildStartHuntButton(
              context,
              4.0,
              method: 'HGSS Starter Soft Reset',
              baseOdds: 8192.0,
              spawns: 3,
              game: 'HeartGold / SoulSilver',
              buttonLabel: Translator.get('shiny_hunt_start_hgss_starters'),
            ));
            gen4Actions.add(const SizedBox(height: 8));
          }
          if (hasGenderVariation) {
            gen4Actions.add(_buildStartHuntButton(
              context,
              4.0,
              method: 'Cute Charm Glitch',
              baseOdds: 100.0 / 21.34,
              buttonLabel: Translator.get('shiny_hunt_start_ccg'),
            ));
            gen4Actions.add(const SizedBox(height: 8));
          }
          gen4Actions.add(_buildStartHuntButton(context, 4.0));

          genTiles.add(
            Gen4ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: Column(children: gen4Actions),
            ),
          );
        } else if (gen == 5.0) {
          genTiles.add(
            Gen5ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: _buildStartHuntButton(context, 5.0),
            ),
          );
        } else if (gen == 6.0) {
          genTiles.add(
            Gen6ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: _buildStartHuntButton(context, 6.0),
            ),
          );
        } else if (gen == 7.0) {
          final isPartnerCap = ShinyLogicHelper.isPartnerCapPikachu(widget.entry);
          final extraAction = isPartnerCap
              ? _buildStartHuntButton(
                  context,
                  7.0,
                  method: 'Soft Reset (QR-Code Pikachu-Tal)',
                  game: 'Ultra Sonne / Ultra Mond',
                  baseOdds: 4096.0,
                )
              : _buildStartHuntButton(context, 7.0);
          genTiles.add(
            Gen7ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: extraAction,
              entry: widget.entry,
            ),
          );
        } else if (gen == 7.5) {
          genTiles.add(
            Gen75ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: _buildStartHuntButton(
                context,
                7.5,
                game: "Let's Go, Pikachu! / Evoli!",
              ),
            ),
          );
        } else if (gen == 8.0) {
          genTiles.add(
            Gen8ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: _buildStartHuntButton(
                context,
                8.0,
                game: 'Schwert / Schild',
              ),
            ),
          );
        } else if (gen == 8.5) {
          genTiles.add(
            Gen85ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: _buildStartHuntButton(
                context,
                8.5,
                game: 'Legenden: Arceus',
              ),
            ),
          );
        } else if (gen == 9.0) {
          genTiles.add(
            Gen9ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: _buildStartHuntButton(
                context,
                9.0,
                game: 'Karmesin / Purpur',
              ),
            ),
          );
        } else if (gen == 9.5) {
          final isPlzaLocked = _shinyCategories.contains('plza_locks') || widget.entry.pokemon.id == 719;
          genTiles.add(
            Gen95ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
              extraAction: isPlzaLocked
                  ? null
                  : _buildStartHuntButton(
                      context,
                      9.5,
                      game: 'Legenden: Z-A',
                    ),
            ),
          );
        }
      }
    }

    if (genTiles.isEmpty && !isLocked) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        maintainState: false,
        leading: Icon(
          isLocked ? Icons.lock : Icons.auto_awesome,
          color: isLocked ? Colors.red : Colors.amber,
        ),
        title: Text(
          Translator.get('shiny_guide_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          if (isLocked)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock, color: Colors.red, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translator.get('shiny_lock_banner', fallback: 'Shiny-Lock aktiv'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ShinyLockService.getShinyLockReason(
                            widget.entry,
                            lang: Translator.currentLanguage,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ...genTiles,
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Translator.get('shiny_guide_missing_note'),
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
      ),
    );
  }
}
