import 'dart:convert';
import 'dart:io';

final Map<String, String> _versionToGen = {
  'red': 'gen_1',
  'blue': 'gen_1',
  'yellow': 'gen_1',
  'gold': 'gen_2',
  'silver': 'gen_2',
  'crystal': 'gen_2',
  'ruby': 'gen_3',
  'sapphire': 'gen_3',
  'emerald': 'gen_3',
  'firered': 'gen_3',
  'leafgreen': 'gen_3',
  'colosseum': 'gen_3',
  'xd': 'gen_3',
  'diamond': 'gen_4',
  'pearl': 'gen_4',
  'platinum': 'gen_4',
  'heartgold': 'gen_4',
  'soulsilver': 'gen_4',
  'black': 'gen_5',
  'white': 'gen_5',
  'black-2': 'gen_5',
  'white-2': 'gen_5',
  'x': 'gen_6',
  'y': 'gen_6',
  'omega-ruby': 'gen_6',
  'alpha-sapphire': 'gen_6',
  'sun': 'gen_7',
  'moon': 'gen_7',
  'ultra-sun': 'gen_7',
  'ultra-moon': 'gen_7',
  'lets-go-pikachu': 'gen_7',
  'lets-go-eevee': 'gen_7',
  'sword': 'gen_8',
  'shield': 'gen_8',
  'the-isle-of-armor-sword': 'gen_8',
  'the-isle-of-armor-shield': 'gen_8',
  'the-crown-tundra-sword': 'gen_8',
  'the-crown-tundra-shield': 'gen_8',
  'brilliant-diamond': 'gen_8',
  'shining-pearl': 'gen_8',
  'legends-arceus': 'gen_8',
  'scarlet': 'gen_9',
  'violet': 'gen_9',
  'the-teal-mask-scarlet': 'gen_9',
  'the-teal-mask-violet': 'gen_9',
  'the-indigo-disk-scarlet': 'gen_9',
  'the-indigo-disk-violet': 'gen_9',
  'legends-z-a': 'gen_9',
};

Map<int, Map<String, Map<String, List<String>>>> _loadCustomEncounters() {
  final file = File('bin/custom_encounters.json');
  if (!file.existsSync()) {
    print('Warnung: bin/custom_encounters.json nicht gefunden.');
    return {};
  }
  final String content = file.readAsStringSync();
  final Map<String, dynamic> jsonData = jsonDecode(content);

  Map<int, Map<String, Map<String, List<String>>>> result = {};
  jsonData.forEach((idStr, genMap) {
    int id = int.parse(idStr);
    result[id] = {};
    (genMap as Map<String, dynamic>).forEach((gen, verMap) {
      result[id]![gen] = {};
      (verMap as Map<String, dynamic>).forEach((ver, locs) {
        result[id]![gen]![ver] = List<String>.from(locs);
      });
    });
  });
  return result;
}

String _cleanLocation(String rawLoc) {
  String loc = rawLoc.toLowerCase();
  loc = loc.replaceAll(RegExp(r'-?area$'), '');
  loc = loc.replaceAll(RegExp(r'-?(south|north|east|west)-towards.*$'), '');
  loc = loc.replaceAll(RegExp(r'-?(before|after)-galactic-intervention$'), '');
  loc = loc.replaceAll(
    RegExp(
      r'^(kanto|johto|hoenn|sinnoh|unova|kalos|alola|galar|paldea|hisui)-',
    ),
    '',
  );
  loc = loc.replaceAll('sea-route-', 'Sea Route ');
  loc = loc.replaceAll('route-', 'Route ');

  if (loc.contains('-') || loc.contains(' ')) {
    loc = loc
        .split(RegExp(r'[- ]'))
        .map((w) {
          if (w.isEmpty) return '';
          return '${w[0].toUpperCase()}${w.substring(1)}';
        })
        .join(' ');
  } else {
    if (loc.isNotEmpty) {
      loc = '${loc[0].toUpperCase()}${loc.substring(1)}';
    }
  }
  return loc.trim();
}

void main() async {
  print('Lade Custom Encounters aus JSON...');
  final customEncounters = _loadCustomEncounters();

  print('Starte Encounter-Download von PokeAPI...');
  final client = HttpClient();
  Map<int, Map<String, Map<String, List<String>>>> finalDatabase = {};

  for (int i = 1; i <= 1025; i++) {
    Map<String, Map<String, List<String>>> pokeData = {};

    if (customEncounters.containsKey(i)) {
      customEncounters[i]!.forEach((gen, versionsMap) {
        pokeData[gen] = {};
        versionsMap.forEach((version, locs) {
          pokeData[gen]![version] = List.from(locs);
        });
      });
    }

    bool success = false;
    for (int attempt = 1; attempt <= 3 && !success; attempt++) {
      try {
        final request = await client.getUrl(
          Uri.parse('https://pokeapi.co/api/v2/pokemon/$i/encounters'),
        );
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(responseBody);

          for (var enc in data) {
            String rawLoc = enc['location_area']['name'];
            String cleanLoc = _cleanLocation(rawLoc);

            for (var vDetails in enc['version_details']) {
              String version = vDetails['version']['name'];
              if (version.contains('-japan')) continue;

              String gen = _versionToGen[version] ?? 'gen_unknown';
              var details = vDetails['encounter_details'] as List;

              if (details.isNotEmpty) {
                Map<String, int> chanceAggregator = {};

                for (var detail in details) {
                  String methodName = detail['method']['name'];
                  int minLvl = detail['min_level'];
                  int maxLvl = detail['max_level'];
                  int chance = detail['chance'];

                  String lvlStr = minLvl == maxLvl
                      ? '$minLvl'
                      : '$minLvl-$maxLvl';
                  String key = '$methodName|||$lvlStr';

                  chanceAggregator[key] = (chanceAggregator[key] ?? 0) + chance;
                }

                pokeData.putIfAbsent(gen, () => {});
                pokeData[gen]!.putIfAbsent(version, () => []);

                chanceAggregator.forEach((key, totalChance) {
                  List<String> parts = key.split('|||');
                  String methodName = parts[0];
                  String lvlStr = parts[1];

                  String finalLocName =
                      '$cleanLoc|||$methodName|||$lvlStr|||$totalChance';

                  if (!pokeData[gen]![version]!.contains(finalLocName)) {
                    pokeData[gen]![version]!.add(finalLocName);
                  }
                });
              }
            }
          }
          success = true;
          await Future.delayed(const Duration(milliseconds: 20));
        } else if (response.statusCode == 429) {
          await Future.delayed(const Duration(seconds: 3));
        } else if (response.statusCode == 404) {
          success = true;
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (pokeData.isNotEmpty) {
      finalDatabase[i] = pokeData;
    }

    if (i % 50 == 0) print('  ... $i/1025 bearbeitet');
  }
  client.close();

  StringBuffer sb = StringBuffer();
  sb.writeln('// Automatisch generierte Datei - NICHT MANUELL ÄNDERN!');
  sb.writeln(
    'const Map<int, Map<String, Map<String, List<String>>>> encountersDatabase = {',
  );

  finalDatabase.forEach((id, genMap) {
    sb.writeln('  $id: {');
    genMap.forEach((gen, verMap) {
      sb.writeln("    '$gen': {");
      verMap.forEach((ver, locs) {
        String locsStr = locs
            .map((l) => "'${l.replaceAll("'", "\\'")}'")
            .join(', ');
        sb.writeln("      '$ver': [$locsStr],");
      });
      sb.writeln('    },');
    });
    sb.writeln('  },');
  });
  sb.writeln('};');

  File('lib/data/encounters_data.dart').writeAsStringSync(sb.toString());
  print('Fertig! lib/data/encounters_data.dart wurde generiert.');
}
