import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dex_view_models.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import '../data/matching_balls_data.dart';
import '../data/encounters_data.dart';
import '../utils/notification_helper.dart';
import 'shiny_guide_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class GameVersion {
  final Color bgColor;
  final Color textColor;
  GameVersion(this.bgColor, this.textColor);
}

final Map<String, GameVersion> _versionColors = {
  'red': GameVersion(const Color(0xFFE3350D), Colors.white),
  'blue': GameVersion(const Color(0xFF3164B6), Colors.white),
  'yellow': GameVersion(const Color(0xFFFFD700), Colors.black),
  'gold': GameVersion(const Color(0xFFDAA520), Colors.black),
  'silver': GameVersion(const Color(0xFFC0C0C0), Colors.black),
  'crystal': GameVersion(const Color(0xFF4FD9E8), Colors.black),
  'ruby': GameVersion(const Color(0xFFA00000), Colors.white),
  'sapphire': GameVersion(const Color(0xFF0000A0), Colors.white),
  'emerald': GameVersion(const Color(0xFF00A000), Colors.white),
  'firered': GameVersion(const Color(0xFFFF7327), Colors.white),
  'leafgreen': GameVersion(const Color(0xFF00DD00), Colors.black),
  'diamond': GameVersion(const Color(0xFFAAAAFF), Colors.black),
  'pearl': GameVersion(const Color(0xFFFFAAAA), Colors.black),
  'platinum': GameVersion(const Color(0xFF999999), Colors.black),
  'heartgold': GameVersion(const Color(0xFFB69E00), Colors.black),
  'soulsilver': GameVersion(const Color(0xFFC0C0E1), Colors.black),
  'black': GameVersion(const Color(0xFF444444), Colors.white),
  'white': GameVersion(const Color(0xFFE1E1E1), Colors.black),
  'black-2': GameVersion(const Color(0xFF444444), Colors.white),
  'white-2': GameVersion(const Color(0xFFE1E1E1), Colors.black),
  'x': GameVersion(const Color(0xFF0070B8), Colors.white),
  'y': GameVersion(const Color(0xFFE30027), Colors.white),
  'omega-ruby': GameVersion(const Color(0xFFAB2813), Colors.white),
  'alpha-sapphire': GameVersion(const Color(0xFF265482), Colors.white),
  'sun': GameVersion(const Color(0xFFF1912B), Colors.white),
  'moon': GameVersion(const Color(0xFF556bb2), Colors.white),
  'ultra-sun': GameVersion(const Color(0xFFE28B0E), Colors.white),
  'ultra-moon': GameVersion(const Color(0xFF00A1E9), Colors.white),
  'lets-go-pikachu': GameVersion(const Color(0xFFF4D23C), Colors.black),
  'lets-go-eevee': GameVersion(const Color(0xFFC8A064), Colors.white),
  'sword': GameVersion(const Color(0xFF00A1E9), Colors.white),
  'shield': GameVersion(const Color(0xFFE30027), Colors.white),
  'the-isle-of-armor-sword': GameVersion(const Color(0xFF007AAB), Colors.white),
  'the-isle-of-armor-shield': GameVersion(
    const Color(0xFFA00018),
    Colors.white,
  ),
  'the-crown-tundra-sword': GameVersion(const Color(0xFF004D73), Colors.white),
  'the-crown-tundra-shield': GameVersion(const Color(0xFF6B000B), Colors.white),
  'brilliant-diamond': GameVersion(const Color(0xFF21A0DB), Colors.black),
  'shining-pearl': GameVersion(const Color(0xFFE4809E), Colors.black),
  'legends-arceus': GameVersion(const Color(0xFF29455B), Colors.white),
  'scarlet': GameVersion(const Color(0xFFD6335A), Colors.white),
  'violet': GameVersion(const Color(0xFF6F35FC), Colors.white),
  'the-teal-mask-scarlet': GameVersion(const Color(0xFF9E1F3D), Colors.white),
  'the-teal-mask-violet': GameVersion(const Color(0xFF4C21B8), Colors.white),
  'the-indigo-disk-scarlet': GameVersion(const Color(0xFF6C1127), Colors.white),
  'the-indigo-disk-violet': GameVersion(const Color(0xFF331382), Colors.white),
  'legends-z-a': GameVersion(const Color(0xFF3BA773), Colors.black),
  'colosseum': GameVersion(const Color(0xFFB89047), Colors.white),
  'xd': GameVersion(const Color(0xFF4C2A69), Colors.white),
};

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

    final matchingBalls =
        matchingBallsDatabase[entry.uniqueId] ??
        matchingBallsDatabase['${entry.pokemon.id}_normal'];
    final List<String> normalBalls = matchingBalls?['normal'] ?? [];
    final List<String> shinyBalls = matchingBalls?['shiny'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translator.get('extra_info') != 'extra_info'
              ? Translator.get('extra_info')
              : 'Zusatzinformationen',
        ),
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
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ColorFiltered(
                colorFilter: isCaught
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                child: Image.network(
                  entry.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${liveDex.isShinyDex ? 'shiny/' : ''}${entry.pokemon.id}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.catching_pokemon, size: 60),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '#${entry.pokemon.id.toString().padLeft(3, '0')}',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              entry.pokemon.getName(provider.currentLanguage),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (entry.displaySuffix.trim().isNotEmpty)
              Text(
                '${Translator.get('form') != 'form' ? Translator.get('form') : 'Form'}: ${entry.displaySuffix.replaceAll('(', '').replaceAll(')', '').trim()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 32),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: SwitchListTile(
                title: const Text(
                  'Shiny Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Als schillernd markieren'),
                secondary: Icon(
                  Icons.star,
                  color: isShiny ? Colors.amber : Colors.grey,
                ),
                value: isShiny,
                activeColor: Colors.amber,
                onChanged: (val) {
                  provider.toggleShiny(dexId, entry.uniqueId);
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.catching_pokemon,
                  color: Colors.redAccent,
                ),
                title: Text(
                  Translator.get('matching_balls') != 'matching_balls'
                      ? Translator.get('matching_balls')
                      : 'Matching Balls',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  _buildBallCard(
                    context,
                    Icons.catching_pokemon,
                    Translator.get('matching_ball_normal') !=
                            'matching_ball_normal'
                        ? Translator.get('matching_ball_normal')
                        : 'Matching Ball (Normal)',
                    normalBalls,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildBallCard(
                    context,
                    Icons.star,
                    Translator.get('matching_ball_shiny') !=
                            'matching_ball_shiny'
                        ? Translator.get('matching_ball_shiny')
                        : 'Matching Ball (Shiny)',
                    shinyBalls,
                    Colors.amber,
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: Text(
                  Translator.get('encounters_title') != 'encounters_title'
                      ? Translator.get('encounters_title')
                      : 'Fundorte & Begegnungen',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: _buildEncountersList(context, entry.pokemon.id),
              ),
            ),
            const SizedBox(height: 16),
            ShinyGuideWidget(pokemon: entry.pokemon),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  Translator.get('ignore_pokemon') != 'ignore_pokemon'
                      ? Translator.get('ignore_pokemon')
                      : 'Aus Dex entfernen',
                ),
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

  Widget _buildVersionBadge(List<String> versions) {
    if (versions.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: versions.asMap().entries.map((entry) {
        int idx = entry.key;
        String ver = entry.value;

        GameVersion? gameVer = _versionColors[ver];
        if (gameVer == null) return const SizedBox.shrink();

        String shortText = Translator.get('badge_$ver');
        if (shortText == 'badge_$ver') {
          shortText = ver.substring(0, 1).toUpperCase();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: gameVer.bgColor,
            border: Border.all(
              color: Colors.black.withOpacity(0.2),
              width: 0.5,
            ),
            borderRadius: BorderRadius.horizontal(
              left: idx == 0 ? const Radius.circular(8) : Radius.zero,
              right: idx == versions.length - 1
                  ? const Radius.circular(8)
                  : Radius.zero,
            ),
          ),
          child: Text(
            shortText,
            style: TextStyle(
              color: gameVer.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildEncountersList(BuildContext context, int pokemonId) {
    try {
      final encounters = encountersDatabase[pokemonId];
      if (encounters == null || encounters.isEmpty) {
        return [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              Translator.get('no_encounters_found') != 'no_encounters_found'
                  ? Translator.get('no_encounters_found')
                  : 'Keine Fundorte bekannt.',
              style: TextStyle(color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ];
      }

      List<Widget> genWidgets = [];
      final sortedGens = encounters.keys.toList()
        ..sort((a, b) {
          int aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          int bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aNum.compareTo(bNum);
        });

      for (var gen in sortedGens) {
        final versionsMap = encounters[gen]!;
        Map<String, List<String>> groupedEncounters = {};

        versionsMap.forEach((ver, locs) {
          String key = locs.join('|||');
          groupedEncounters.putIfAbsent(key, () => []).add(ver);
        });

        List<Widget> versionWidgets = [];

        groupedEncounters.forEach((locationsStr, versions) {
          final locations = locationsStr.split('|||');
          final String formattedLocations = locations
              .map((loc) {
                String base = loc;
                String method = '';
                if (loc.contains(' (')) {
                  int bracketIndex = loc.indexOf(' (');
                  base = loc.substring(0, bracketIndex);
                  method = loc.substring(bracketIndex + 2, loc.length - 1);
                }
                String transBase = Translator.get(base);
                if (transBase == base) {
                  transBase = Translator.get('loc_$base');
                  if (transBase == 'loc_$base') {
                    transBase = base;
                  }
                }
                String transMethod = '';
                if (method.isNotEmpty) {
                  String tMethod = Translator.get('method_$method');
                  if (tMethod == 'method_$method') {
                    tMethod = Translator.get(method);
                    if (tMethod == method) tMethod = method;
                  }
                  transMethod = ' ($tMethod)';
                }
                return '  $transBase$transMethod';
              })
              .join('\n');

          versionWidgets.add(
            ListTile(
              leading: _buildVersionBadge(versions),
              title: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  formattedLocations,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              minLeadingWidth: 40,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          );
        });

        if (gen == 'gen_2' && pokemonId >= 252 && pokemonId <= 257) {
          versionWidgets.add(
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.tertiaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.memory,
                          size: 20,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            Translator.get('shiny_mail_writer_note'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.language),
                      label: Text(Translator.get('tutorial_mail_writer_main')),
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes',
                        );
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          NotificationHelper.showError(
                            '${Translator.get('error_launch_url')} $url',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.code),
                      label: Text(
                        Translator.get('tutorial_mail_writer_scripts'),
                      ),
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes#Gen3Giver_scripts',
                        );
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          NotificationHelper.showError(
                            '${Translator.get('error_launch_url')} $url',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        genWidgets.add(
          ExpansionTile(
            title: Text(
              Translator.get(gen) != gen
                  ? Translator.get(gen)
                  : gen.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: versionWidgets,
          ),
        );
      }

      genWidgets.add(
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
                  Translator.get('encounter_missing_note') !=
                          'encounter_missing_note'
                      ? Translator.get('encounter_missing_note')
                      : 'Hinweis: Wenn eine Edition nicht aufgeführt ist, ist das Pokémon dort in der Regel nur durch Entwicklung, Tausch oder Transfer erhältlich.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      return genWidgets;
    } catch (e) {
      NotificationHelper.showError(
        '${Translator.get('error_loading_encounters')} $e',
      );
      return [const SizedBox.shrink()];
    }
  }

  Widget _buildBallCard(
    BuildContext context,
    IconData icon,
    String title,
    List<String> ballKeys,
    Color iconColor,
  ) {
    bool isAny = ballKeys.isEmpty || ballKeys.contains('any_ball');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isAny
              ? Text(
                  Translator.get('any_ball'),
                  style: const TextStyle(fontSize: 15),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ballKeys.map((key) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ballImageUrls.containsKey(key))
                            Image.network(
                              ballImageUrls[key]!,
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.catching_pokemon, size: 24),
                            ),
                          if (ballImageUrls.containsKey(key))
                            const SizedBox(width: 8),
                          Text(
                            Translator.get('ball_$key'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  void _confirmIgnore(BuildContext context, DexProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          Translator.get('ignore_confirm_title') != 'ignore_confirm_title'
              ? Translator.get('ignore_confirm_title')
              : 'Pokémon entfernen?',
        ),
        content: Text(
          Translator.get('ignore_confirm_text') != 'ignore_confirm_text'
              ? Translator.get('ignore_confirm_text')
              : 'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.',
        ),
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
            child: Text(
              Translator.get('ignore_pokemon') != 'ignore_pokemon'
                  ? Translator.get('ignore_pokemon')
                  : 'Entfernen',
            ),
          ),
        ],
      ),
    );
  }
}
