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

List<String> _groupRoutes(List<String> locations) {
  Map<String, List<String>> landRoutes = {};
  Map<String, List<String>> waterRoutes = {};
  List<String> others = [];

  for (String loc in locations) {
    final waterMatch = RegExp(
      r'^Sea Route (\d+)(?:\s\((.*?)\))?$',
    ).firstMatch(loc);
    if (waterMatch != null) {
      String num = waterMatch.group(1)!;
      String method = waterMatch.group(2) ?? '';
      waterRoutes.putIfAbsent(method, () => []).add(num);
      continue;
    }
    final landMatch = RegExp(r'^Route (\d+)(?:\s\((.*?)\))?$').firstMatch(loc);
    if (landMatch != null) {
      String num = landMatch.group(1)!;
      String method = landMatch.group(2) ?? '';
      landRoutes.putIfAbsent(method, () => []).add(num);
      continue;
    }
    others.add(loc);
  }

  List<String> result = [];
  landRoutes.forEach((method, numbers) {
    numbers.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    String combined = 'Route ${numbers.join(', ')}';
    if (method.isNotEmpty) combined += ' ($method)';
    result.add(combined);
  });
  waterRoutes.forEach((method, numbers) {
    numbers.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    String combined = 'Sea Route ${numbers.join(', ')}';
    if (method.isNotEmpty) combined += ' ($method)';
    result.add(combined);
  });
  result.addAll(others);
  return result;
}

List<String> _deduplicate(List<String> locs) {
  Map<String, List<String>> byBase = {};
  for (String loc in locs) {
    String base = loc;
    if (loc.contains(' (')) {
      base = loc.substring(0, loc.indexOf(' ('));
    }
    byBase.putIfAbsent(base, () => []).add(loc);
  }

  List<String> result = [];
  byBase.forEach((base, list) {
    if (list.length == 1) {
      result.add(list.first.replaceAll('(Gift/Starter)', '(Gift)'));
    } else {
      String? best;
      int bestScore = -1;
      for (String l in list) {
        int score = 0;
        if (l.contains('(Starter)'))
          score = 100;
        else if (l.contains('(Fighting Dojo)'))
          score = 95;
        else if (l.contains('(Gift/Starter)'))
          score = 90;
        else if (l.contains('(Gift)'))
          score = 80;
        else if (l.contains('(Fossil)'))
          score = 70;
        else if (l.contains('(Egg)'))
          score = 65;
        else if (l.contains('(Trade)'))
          score = 60;
        else if (l.contains('(Surf)') || l.contains('(Rod)'))
          score = 20;
        else if (l.contains('('))
          score = 10;
        if (score > bestScore) {
          bestScore = score;
          best = l;
        }
      }
      if (best != null) {
        result.add(best.replaceAll('(Gift/Starter)', '(Gift)'));
      } else {
        result.add(list.first);
      }
    }
  });
  return result.toSet().toList();
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

              String methodSuffix = '';
              var details = vDetails['encounter_details'] as List;
              if (details.isNotEmpty) {
                String methodName = details.first['method']['name'];
                if (methodName == 'surf')
                  methodSuffix = ' (Surf)';
                else if (methodName == 'old-rod')
                  methodSuffix = ' (Old Rod)';
                else if (methodName == 'good-rod')
                  methodSuffix = ' (Good Rod)';
                else if (methodName == 'super-rod')
                  methodSuffix = ' (Super Rod)';
                else if (methodName.contains('fly'))
                  methodSuffix = ' (Fly)';
                else if (methodName.contains('gift') ||
                    methodName == 'only-one')
                  methodSuffix = ' (Gift/Starter)';
                else if (methodName == 'trade')
                  methodSuffix = ' (Trade)';
              }

              String finalLocName = '$cleanLoc$methodSuffix';
              pokeData.putIfAbsent(gen, () => {});
              pokeData[gen]!.putIfAbsent(version, () => []);

              if (!pokeData[gen]![version]!.contains(finalLocName)) {
                pokeData[gen]![version]!.add(finalLocName);
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
      pokeData.forEach((gen, verMap) {
        verMap.forEach((ver, locs) {
          verMap[ver] = _deduplicate(_groupRoutes(locs));
        });
      });
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
