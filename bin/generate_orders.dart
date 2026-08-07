import 'dart:convert';
import 'dart:io';

void main() async {
  print('Lade offizielle Pokédex-Reihenfolgen herunter...');

  final hardcodedOrders = {
    'lumiose': <int>[],
    'lumiose-dimensions': <int>[],
    'mega-dex': [
      3,
      6,
      9,
      15,
      18,
      65,
      80,
      94,
      115,
      127,
      130,
      142,
      150,
      181,
      208,
      212,
      214,
      229,
      248,
      254,
      257,
      260,
      282,
      302,
      303,
      306,
      308,
      310,
      319,
      323,
      334,
      354,
      359,
      362,
      373,
      376,
      380,
      381,
      384,
      428,
      445,
      448,
      460,
      475,
      719,
    ],
    'icognito-dex': [201],
  };

  final regionalDexEndpoints = {
    // Gen 1 & Remakes & Let's Go
    'kanto': ['kantoRegionalOrder', 'kanto_regional'],
    'letsgo-kanto': ['letsgoKantoRegionalOrder', 'letsgo_kanto_regional'],

    // Gen 2 & Remakes (HG/SS)
    'original-johto': ['johtoRegionalOrder', 'johto_regional'],
    'updated-johto': ['updatedJohtoRegionalOrder', 'updated_johto_regional'],

    // Gen 3 & Remakes (OR/AS)
    'hoenn': ['hoennRegionalOrder', 'hoenn_regional'],
    'updated-hoenn': ['updatedHoennRegionalOrder', 'updated_hoenn_regional'],

    // Gen 4 (Diamant/Perl/BDSP & Platin)
    'original-sinnoh': ['sinnohRegionalOrder', 'sinnoh_regional'],
    'extended-sinnoh': [
      'extendedSinnohRegionalOrder',
      'extended_sinnoh_regional',
    ],

    // Gen 5 (Schwarz/Weiß & S2/W2)
    'original-unova': ['unovaRegionalOrder', 'unova_regional'],
    'updated-unova': ['updatedUnovaRegionalOrder', 'updated_unova_regional'],

    // Gen 6 (X/Y)
    'kalos-central': ['kalosCentralRegionalOrder', 'kalos_central_regional'],
    'kalos-coastal': ['kalosCoastalRegionalOrder', 'kalos_coastal_regional'],
    'kalos-mountain': ['kalosMountainRegionalOrder', 'kalos_mountain_regional'],

    // Gen 7 (Sonne/Mond)
    'original-alola': ['alolaRegionalOrder', 'alola_regional'],
    'original-melemele': ['melemeleRegionalOrder', 'melemele_regional'],
    'original-akala': ['akalaRegionalOrder', 'akala_regional'],
    'original-ulaula': ['ulaulaRegionalOrder', 'ulaula_regional'],
    'original-poni': ['poniRegionalOrder', 'poni_regional'],

    // Gen 7 (Ultra Sonne/Ultra Mond)
    'updated-alola': ['updatedAlolaRegionalOrder', 'updated_alola_regional'],
    'updated-melemele': [
      'updatedMelemeleRegionalOrder',
      'updated_melemele_regional',
    ],
    'updated-akala': ['updatedAkalaRegionalOrder', 'updated_akala_regional'],
    'updated-ulaula': ['updatedUlaulaRegionalOrder', 'updated_ulaula_regional'],
    'updated-poni': ['updatedPoniRegionalOrder', 'updated_poni_regional'],

    // Gen 8 (Schwert/Schild & Legenden Arceus)
    'galar': ['galarRegionalOrder', 'galar_regional'],
    'isle-of-armor': ['isleOfArmorRegionalOrder', 'isle_of_armor_regional'],
    'crown-tundra': ['crownTundraRegionalOrder', 'crown_tundra_regional'],
    'hisui': ['hisuiRegionalOrder', 'hisui_regional'],

    // Gen 9 (Karmesin/Purpur & Legenden Z-A)
    'paldea': ['paldeaRegionalOrder', 'paldea_regional'],
    'kitakami': ['kitakamiRegionalOrder', 'kitakami_regional'],
    'blueberry': ['blueberryRegionalOrder', 'blueberry_regional'],

    // Does not exist at the moment
    // 'lumiose': ['lumioseRegionalOrder', 'lumiose_regional'],
    // 'lumiose-dimensions': [
    //   'lumioseDimensionsRegionalOrder',
    //   'lumiose_dimensions_regional',
    // ],
    'mega-dex': ['megaDexOrder', 'mega_dex'],
    'icognito-dex': ['icognitoDexOrder', 'icognito_dex'],
  };

  Map<String, List<int>> fetchedOrders = {};

  for (var entry in regionalDexEndpoints.entries) {
    try {
      final varName = entry.value[0];
      if (hardcodedOrders.containsKey(entry.key)) {
        fetchedOrders[varName] = hardcodedOrders[entry.key]!;
        print('Lade Dex: ${entry.key}... (Hardcoded)');
      } else {
        fetchedOrders[varName] = await fetchPokedexOrder(entry.key);
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } catch (e) {
      print('FEHLER beim Laden von ${entry.key}: $e');
      fetchedOrders[entry.value[0]] = [];
    }
  }

  // Nationale Obergrenzen
  final nationalMaxIds = {
    'kanto': 151,
    'johto': 251,
    'hoenn': 386,
    'sinnoh': 493,
    'unova': 649,
    'kalos': 721,
    'alola': 809,
    'galar': 905,
    'paldea': 1025,
  };

  StringBuffer sb = StringBuffer();
  sb.writeln('// Automatisch generierte Datei - NICHT MANUELL ÄNDERN!\n');

  sb.writeln('// ==========================================');
  sb.writeln('// 1. REGIONALE REIHENFOLGEN');
  sb.writeln('// ==========================================');
  for (var entry in fetchedOrders.entries) {
    sb.writeln('const List<int> ${entry.key} = [${entry.value.join(', ')}];');
  }

  sb.writeln('\n// ==========================================');
  sb.writeln('// 2. NATIONALE REIHENFOLGEN');
  sb.writeln('// ==========================================');
  for (var entry in nationalMaxIds.entries) {
    sb.writeln(
      'final List<int> ${entry.key}NationalOrder = List.generate(${entry.value}, (i) => i + 1);',
    );
  }

  sb.writeln('\n// ==========================================');
  sb.writeln('// 3. ALLE BEREITGESTELLTEN DEXE (FÜR DYNAMISCHE UI)');
  sb.writeln('// ==========================================');
  sb.writeln('final Map<String, List<int>> allAvailableDexes = {');
  sb.writeln("  'national_overall': paldeaNationalOrder,");

  for (var entry in regionalDexEndpoints.values) {
    final varName = entry[0];
    final mapKey = entry[1];
    sb.writeln("  '$mapKey': $varName,");
  }

  for (var entry in nationalMaxIds.entries) {
    final mapKey = '${entry.key}_national';
    final varName = '${entry.key}NationalOrder';
    sb.writeln("  '$mapKey': $varName,");
  }

  sb.writeln('};');

  File('lib/data/dex_orders.dart').writeAsStringSync(sb.toString());
  print('\nFertig! Dexe und dynamische Map erstellt.');
}

Future<List<int>> fetchPokedexOrder(String dexName) async {
  print('Lade Dex: $dexName...');
  final client = HttpClient();

  int maxRetries = 3;
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final request = await client.getUrl(
        Uri.parse('https://pokeapi.co/api/v2/pokedex/$dexName'),
      );
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 && responseBody.trim().isNotEmpty) {
        final data = jsonDecode(responseBody);
        List<int> nationalIds = [];

        for (var entry in data['pokemon_entries']) {
          final url = entry['pokemon_species']['url'] as String;
          final segments = url.split('/');
          final nationalId = int.parse(segments[segments.length - 2]);
          nationalIds.add(nationalId);
        }

        client.close();
        return nationalIds;
      }

      if (response.statusCode == 429) {
        print(
          '  -> Rate Limit erreicht! Warte 3 Sekunden... (Versuch $attempt)',
        );
        await Future.delayed(const Duration(seconds: 3));
      } else if (response.statusCode == 404) {
        print('  -> Dex "$dexName" nicht gefunden (404)!');
        client.close();
        return [];
      } else {
        print(
          '  -> Fehler ${response.statusCode} bei $dexName. Warte... (Versuch $attempt)',
        );
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('  -> Netzwerk-Timeout bei $dexName (Versuch $attempt)');
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  client.close();
  throw Exception(
    'Konnte Dex $dexName nach $maxRetries Versuchen nicht laden.',
  );
}
