import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_translations.dart';
import '../../../services/database_service.dart';
import '../../../utils/notification_helper.dart';

class GameVersion {
  final Color bgColor;
  final Color textColor;
  const GameVersion(this.bgColor, this.textColor);
}

const Map<String, GameVersion> versionColors = {
  'red': GameVersion(Color(0xFFE3350D), Colors.white),
  'blue': GameVersion(Color(0xFF3164B6), Colors.white),
  'yellow': GameVersion(Color(0xFFFFD700), Colors.black),
  'gold': GameVersion(Color(0xFFDAA520), Colors.black),
  'silver': GameVersion(Color(0xFFC0C0C0), Colors.black),
  'crystal': GameVersion(Color(0xFF4FD9E8), Colors.black),
  'ruby': GameVersion(Color(0xFFA00000), Colors.white),
  'sapphire': GameVersion(Color(0xFF0000A0), Colors.white),
  'emerald': GameVersion(Color(0xFF00A000), Colors.white),
  'firered': GameVersion(Color(0xFFFF7327), Colors.white),
  'leafgreen': GameVersion(Color(0xFF00DD00), Colors.black),
  'diamond': GameVersion(Color(0xFFAAAAFF), Colors.black),
  'pearl': GameVersion(Color(0xFFFFAAAA), Colors.black),
  'platinum': GameVersion(Color(0xFF999999), Colors.black),
  'heartgold': GameVersion(Color(0xFFB69E00), Colors.black),
  'soulsilver': GameVersion(Color(0xFFC0C0E1), Colors.black),
  'black': GameVersion(Color(0xFF444444), Colors.white),
  'white': GameVersion(Color(0xFFE1E1E1), Colors.black),
  'black-2': GameVersion(Color(0xFF444444), Colors.white),
  'white-2': GameVersion(Color(0xFFE1E1E1), Colors.black),
  'x': GameVersion(Color(0xFF0070B8), Colors.white),
  'y': GameVersion(Color(0xFFE30027), Colors.white),
  'omega-ruby': GameVersion(Color(0xFFAB2813), Colors.white),
  'alpha-sapphire': GameVersion(Color(0xFF265482), Colors.white),
  'sun': GameVersion(Color(0xFFF1912B), Colors.white),
  'moon': GameVersion(Color(0xFF556bb2), Colors.white),
  'ultra-sun': GameVersion(Color(0xFFE28B0E), Colors.white),
  'ultra-moon': GameVersion(Color(0xFF00A1E9), Colors.white),
  'lets-go-pikachu': GameVersion(Color(0xFFF4D23C), Colors.black),
  'lets-go-eevee': GameVersion(Color(0xFFC8A064), Colors.white),
  'sword': GameVersion(Color(0xFF00A1E9), Colors.white),
  'shield': GameVersion(Color(0xFFE30027), Colors.white),
  'the-isle-of-armor-sword': GameVersion(Color(0xFF007AAB), Colors.white),
  'the-isle-of-armor-shield': GameVersion(Color(0xFFA00018), Colors.white),
  'the-crown-tundra-sword': GameVersion(Color(0xFF004D73), Colors.white),
  'the-crown-tundra-shield': GameVersion(Color(0xFF6B000B), Colors.white),
  'brilliant-diamond': GameVersion(Color(0xFF21A0DB), Colors.black),
  'shining-pearl': GameVersion(Color(0xFFE4809E), Colors.black),
  'legends-arceus': GameVersion(Color(0xFF29455B), Colors.white),
  'scarlet': GameVersion(Color(0xFFD6335A), Colors.white),
  'violet': GameVersion(Color(0xFF6F35FC), Colors.white),
  'the-teal-mask-scarlet': GameVersion(Color(0xFF9E1F3D), Colors.white),
  'the-teal-mask-violet': GameVersion(Color(0xFF4C21B8), Colors.white),
  'the-indigo-disk-scarlet': GameVersion(Color(0xFF6C1127), Colors.white),
  'the-indigo-disk-violet': GameVersion(Color(0xFF331382), Colors.white),
  'legends-z-a': GameVersion(Color(0xFF3BA773), Colors.black),
  'colosseum': GameVersion(Color(0xFFB89047), Colors.white),
  'xd': GameVersion(Color(0xFF4C2A69), Colors.white),
};

class EncountersWidget extends StatelessWidget {
  final int pokemonId;
  final GlobalKey encountersKey;

  const EncountersWidget({
    super.key,
    required this.pokemonId,
    required this.encountersKey,
  });

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        NotificationHelper.showError(
          '${Translator.get('error_launch_url')} $urlString',
        );
      }
    } catch (e) {
      NotificationHelper.showError('${Translator.get('error_launch_url')} $e');
    }
  }

  Widget _buildVersionBadge(List<String> versions) {
    if (versions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 2,
      runSpacing: 4,
      children: versions.map((ver) {
        GameVersion? gameVer = versionColors[ver];
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
              color: Colors.black.withValues(alpha: 0.2),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            shortText,
            style: TextStyle(
              color: gameVer.textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _translateLoc(String loc) {
    String transBase = Translator.get(loc);
    if (transBase == loc) {
      transBase = Translator.get('loc_$loc');
      if (transBase == 'loc_$loc') {
        return loc;
      }
    }
    return transBase;
  }

  String _translateMethod(String method) {
    if (method.isEmpty) return '';
    String tMethod = Translator.get('method_$method');
    if (tMethod == 'method_$method') {
      tMethod = Translator.get(method);
      if (tMethod == method) return method;
    }
    return tMethod;
  }

  Widget _buildGlitchNote(
    BuildContext context,
    String textKey,
    String btn1Key,
    String btn1Url, {
    String? secondBtnTitle,
    String? secondBtnUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.tertiary.withValues(alpha: 0.3),
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
                    Translator.get(textKey),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
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
              label: Text(Translator.get(btn1Key)),
              onPressed: () => _launchURL(btn1Url),
            ),
          ),
          if (secondBtnTitle != null && secondBtnUrl != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.code),
                label: Text(Translator.get(secondBtnTitle)),
                onPressed: () => _launchURL(secondBtnUrl),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildEncountersList(
    BuildContext context,
    Map<String, Map<String, List<String>>> encounters,
  ) {
    if (encounters.isEmpty) {
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
        String key = locs.join('|||||');
        groupedEncounters.putIfAbsent(key, () => []).add(ver);
      });

      List<Widget> versionWidgets = [];
      groupedEncounters.forEach((locationsStr, versions) {
        final locations = locationsStr.split('|||||');
        List<Widget> locationRows = locations.map((loc) {
          if (loc.contains('|||')) {
            final parts = loc.split('|||');
            final baseLoc = _translateLoc(parts[0]);
            final method = _translateMethod(parts.length > 1 ? parts[1] : '');
            final lvl = parts.length > 2 ? parts[2] : '';
            final chance = parts.length > 3 ? '${parts[3]} %' : '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baseLoc,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (method.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.grass,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                method,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      lvl.isNotEmpty ? 'Lv. $lvl' : '',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      chance,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          } else {
            String base = loc;
            String method = '';
            if (loc.contains(' (')) {
              int bracketIndex = loc.indexOf(' (');
              base = loc.substring(0, bracketIndex);
              method = loc.substring(bracketIndex + 2, loc.length - 1);
            }
            String transBase = _translateLoc(base);
            String transMethod = method.isNotEmpty
                ? ' (${_translateMethod(method)})'
                : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '• $transBase$transMethod',
                style: const TextStyle(fontSize: 13),
              ),
            );
          }
        }).toList();

        versionWidgets.add(
          Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                title: _buildVersionBadge(versions),
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...locationRows,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });

      if (gen == 'gen_2' && pokemonId >= 252 && pokemonId <= 257) {
        versionWidgets.add(
          _buildGlitchNote(
            context,
            'shiny_mail_writer_note',
            'tutorial_mail_writer_main',
            'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes',
            secondBtnTitle: 'tutorial_mail_writer_scripts',
            secondBtnUrl:
                'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes#Gen3Giver_scripts',
          ),
        );
      }

      if (gen == 'gen_1' && pokemonId == 151) {
        versionWidgets.add(
          _buildGlitchNote(
            context,
            'mew_glitch_note',
            'tutorial_mew_normal_link',
            'https://www.reddit.com/r/gaming/comments/47uono/heres_a_guide_on_catching_a_level_7_mew_on_the/',
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: encountersKey,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.map, color: Colors.blue),
        title: Text(
          Translator.get('encounters_title') != 'encounters_title'
              ? Translator.get('encounters_title')
              : 'Fundorte & Begegnungen',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          FutureBuilder<Map<String, Map<String, List<String>>>?>(
            future: DatabaseService.instance.getEncounters(pokemonId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data ?? {};
              return Column(children: _buildEncountersList(context, data));
            },
          ),
        ],
      ),
    );
  }
}
