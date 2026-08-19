import 'dart:convert';
import 'dart:io';

void main() async {
  print('Generiere Catch Data (Weight & Speed) von PokeAPI...');
  final client = HttpClient();
  Map<int, Map<String, dynamic>> catchData = {};

  for (int i = 1; i <= 1025; i++) {
    bool success = false;
    for (int attempt = 1; attempt <= 3 && !success; attempt++) {
      try {
        final request = await client.getUrl(
          Uri.parse('https://pokeapi.co/api/v2/pokemon/$i'),
        );
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          double weightKg = (data['weight'] ?? 0) / 10.0;

          int speed = 0;
          for (var stat in data['stats']) {
            if (stat['stat']['name'] == 'speed') {
              speed = stat['base_stat'];
              break;
            }
          }

          catchData[i] = {'weight': weightKg, 'speed': speed};
          success = true;
          await Future.delayed(const Duration(milliseconds: 20));
        } else if (response.statusCode == 429) {
          await Future.delayed(const Duration(seconds: 3));
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (i % 50 == 0) print('  ... $i/1025 bearbeitet');
  }
  client.close();

  StringBuffer sb = StringBuffer();
  sb.writeln('// Automatisch generierte Datei - NICHT MANUELL ÄNDERN!');
  sb.writeln('const Map<int, Map<String, dynamic>> catchDataDatabase = {');
  catchData.forEach((id, data) {
    sb.writeln(
      '  $id: {\'weight\': ${data['weight']}, \'speed\': ${data['speed']}},',
    );
  });
  sb.writeln('};');

  File('lib/data/catch_data.dart').writeAsStringSync(sb.toString());
  print('Fertig! lib/data/catch_data.dart wurde erfolgreich generiert.');
}
