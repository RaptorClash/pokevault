import 'dart:convert';
import 'dart:io';

void main() async {
  print('Lade Evolutionsketten herunter... (das dauert einen Moment)');
  final client = HttpClient();
  Map<String, dynamic> allChains = {};

  for (int i = 1; i <= 550; i++) {
    try {
      final request = await client.getUrl(
        Uri.parse('https://pokeapi.co/api/v2/evolution-chain/$i'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        if (data['chain'] != null) {
          allChains[i.toString()] = _parseChain(data['chain']);
        }
      }
    } catch (e) {}
    if (i % 50 == 0) print('  ... $i/550 geprüft');
  }
  client.close();

  String jsonString = jsonEncode(allChains);

  StringBuffer sb = StringBuffer();
  sb.writeln("import 'dart:convert';");
  sb.writeln();
  sb.writeln("// Automatisch generierte Datei - NICHT MANUELL ÄNDERN!");
  sb.writeln("final Map<String, dynamic> evolutionDatabase = jsonDecode(r'''");
  sb.writeln(jsonString);
  sb.writeln("''');");

  File('lib/data/evolution_data.dart').writeAsStringSync(sb.toString());
  print('Fertig! lib/data/evolution_data.dart wurde erstellt.');
}

Map<String, dynamic> _parseChain(Map<String, dynamic> node) {
  String speciesUrl = node['species']['url'];
  int speciesId = int.parse(speciesUrl.split('/').reversed.elementAt(1));

  List<Map<String, dynamic>> evolvesTo = [];
  if (node['evolves_to'] != null) {
    for (var nextNode in node['evolves_to']) {
      evolvesTo.add(_parseChain(nextNode));
    }
  }

  List<Map<String, dynamic>> details = [];
  if (node['evolution_details'] != null) {
    for (var d in node['evolution_details']) {
      details.add({
        'trigger': d['trigger']?['name'],
        'min_level': d['min_level'],
        'item': d['item']?['name'],
        'held_item': d['held_item']?['name'],
        'min_happiness': d['min_happiness'],
        'time_of_day': d['time_of_day'],
        'known_move': d['known_move']?['name'],
        'location': d['location']?['name'],
      });
    }
  }

  return {
    'species_id': speciesId,
    'is_baby': node['is_baby'] ?? false,
    'details': details,
    'evolves_to': evolvesTo,
  };
}
