import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/dex_view_models.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../services/database_service.dart';
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


  bool _shouldShowGen(double gen) {
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
    List<Widget> genTiles = [];

    List<double> generations = [
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
              ],
            ),
          );
        } else if (gen == 2.0) {
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
              ],
            ),
          );
        } else if (gen == 4.0) {
          genTiles.add(
            Gen4ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 5.0) {
          genTiles.add(
            Gen5ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 6.0) {
          genTiles.add(
            Gen6ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 7.0) {
          genTiles.add(
            Gen7ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 7.5) {
          genTiles.add(
            Gen75ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 8.0) {
          genTiles.add(
            Gen8ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 8.5) {
          genTiles.add(
            Gen85ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 9.0) {
          genTiles.add(
            Gen9ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        } else if (gen == 9.5) {
          genTiles.add(
            Gen95ShinyGuide(
              pokemon: widget.entry.pokemon,
              shinyCategories: _shinyCategories,
              title: resolvedTitle,
              onLaunchUrl: _launchURL,
            ),
          );
        }
      }
    }

    if (genTiles.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.amber),
        title: Text(
          Translator.get('shiny_guide_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
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
