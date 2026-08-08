import 'dart:convert';
import 'dart:io';

void main() async {
  print('Lade offizielle Pokédex-Reihenfolgen herunter...');

  final hardcodedOrders = {
    'lumiose': [
      152,
      153,
      154,
      498,
      499,
      500,
      158,
      159,
      160,
      661,
      662,
      663,
      659,
      660,
      664,
      665,
      666,
      13,
      14,
      15,
      16,
      17,
      18,
      179,
      180,
      181,
      504,
      505,
      406,
      315,
      407,
      129,
      130,
      688,
      689,
      120,
      121,
      669,
      670,
      671,
      672,
      673,
      677,
      678,
      667,
      668,
      674,
      675,
      568,
      569,
      702,
      172,
      25,
      26,
      173,
      35,
      36,
      167,
      168,
      23,
      24,
      63,
      64,
      65,
      92,
      93,
      94,
      543,
      544,
      545,
      679,
      680,
      681,
      69,
      70,
      71,
      511,
      512,
      513,
      514,
      515,
      516,
      307,
      308,
      309,
      310,
      280,
      281,
      282,
      475,
      228,
      229,
      333,
      334,
      531,
      682,
      683,
      684,
      685,
      133,
      134,
      135,
      136,
      196,
      197,
      470,
      471,
      700,
      427,
      428,
      353,
      354,
      582,
      583,
      584,
      322,
      323,
      449,
      450,
      529,
      530,
      551,
      552,
      553,
      66,
      67,
      68,
      443,
      444,
      445,
      703,
      302,
      303,
      359,
      447,
      448,
      79,
      80,
      199,
      318,
      319,
      602,
      603,
      604,
      147,
      148,
      149,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      618,
      676,
      686,
      687,
      690,
      691,
      692,
      693,
      704,
      705,
      706,
      225,
      361,
      362,
      478,
      459,
      460,
      712,
      713,
      123,
      212,
      127,
      214,
      587,
      701,
      708,
      709,
      559,
      560,
      714,
      715,
      707,
      607,
      608,
      609,
      142,
      696,
      697,
      698,
      699,
      95,
      208,
      304,
      305,
      306,
      694,
      695,
      710,
      711,
      246,
      247,
      248,
      656,
      657,
      658,
      870,
      650,
      651,
      652,
      227,
      653,
      654,
      655,
      371,
      372,
      373,
      115,
      780,
      374,
      375,
      376,
      716,
      717,
      718,
      719,
      150,
    ],
    'lumiose-dimensions': [
      56,
      57,
      979,
      52,
      53,
      863,
      83,
      865,
      104,
      105,
      137,
      233,
      474,
      951,
      952,
      957,
      958,
      959,
      962,
      969,
      970,
      479,
      971,
      972,
      769,
      770,
      352,
      973,
      615,
      977,
      978,
      996,
      997,
      998,
      999,
      1000,
      211,
      904,
      252,
      253,
      254,
      255,
      256,
      257,
      258,
      259,
      260,
      349,
      350,
      433,
      358,
      876,
      509,
      510,
      517,
      518,
      538,
      539,
      562,
      563,
      867,
      767,
      768,
      827,
      828,
      852,
      853,
      778,
      900,
      877,
      622,
      623,
      821,
      822,
      823,
      174,
      39,
      40,
      926,
      927,
      396,
      397,
      398,
      325,
      326,
      931,
      739,
      740,
      932,
      933,
      934,
      316,
      317,
      41,
      42,
      169,
      935,
      936,
      937,
      942,
      943,
      848,
      849,
      944,
      945,
      335,
      336,
      439,
      122,
      866,
      590,
      591,
      485,
      721,
      638,
      639,
      640,
      647,
      648,
      649,
      720,
      802,
      808,
      809,
      491,
      380,
      381,
      382,
      383,
      384,
      801,
      807,
    ],
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
      382,
      383,
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
    'kanto': ['kantoRegionalOrder', 'kanto_regional'],
    'letsgo-kanto': ['letsgoKantoRegionalOrder', 'letsgo_kanto_regional'],
    'original-johto': ['johtoRegionalOrder', 'johto_regional'],
    'updated-johto': ['updatedJohtoRegionalOrder', 'updated_johto_regional'],
    'hoenn': ['hoennRegionalOrder', 'hoenn_regional'],
    'updated-hoenn': ['updatedHoennRegionalOrder', 'updated_hoenn_regional'],
    'original-sinnoh': ['sinnohRegionalOrder', 'sinnoh_regional'],
    'extended-sinnoh': [
      'extendedSinnohRegionalOrder',
      'extended_sinnoh_regional',
    ],
    'original-unova': ['unovaRegionalOrder', 'unova_regional'],
    'updated-unova': ['updatedUnovaRegionalOrder', 'updated_unova_regional'],
    'kalos-central': ['kalosCentralRegionalOrder', 'kalos_central_regional'],
    'kalos-coastal': ['kalosCoastalRegionalOrder', 'kalos_coastal_regional'],
    'kalos-mountain': ['kalosMountainRegionalOrder', 'kalos_mountain_regional'],
    'original-alola': ['alolaRegionalOrder', 'alola_regional'],
    'original-melemele': ['melemeleRegionalOrder', 'melemele_regional'],
    'original-akala': ['akalaRegionalOrder', 'akala_regional'],
    'original-ulaula': ['ulaulaRegionalOrder', 'ulaula_regional'],
    'original-poni': ['poniRegionalOrder', 'poni_regional'],
    'updated-alola': ['updatedAlolaRegionalOrder', 'updated_alola_regional'],
    'updated-melemele': [
      'updatedMelemeleRegionalOrder',
      'updated_melemele_regional',
    ],
    'updated-akala': ['updatedAkalaRegionalOrder', 'updated_akala_regional'],
    'updated-ulaula': ['updatedUlaulaRegionalOrder', 'updated_ulaula_regional'],
    'updated-poni': ['updatedPoniRegionalOrder', 'updated_poni_regional'],
    'galar': ['galarRegionalOrder', 'galar_regional'],
    'isle-of-armor': ['isleOfArmorRegionalOrder', 'isle_of_armor_regional'],
    'crown-tundra': ['crownTundraRegionalOrder', 'crown_tundra_regional'],
    'hisui': ['hisuiRegionalOrder', 'hisui_regional'],
    'paldea': ['paldeaRegionalOrder', 'paldea_regional'],
    'kitakami': ['kitakamiRegionalOrder', 'kitakami_regional'],
    'blueberry': ['blueberryRegionalOrder', 'blueberry_regional'],
    'lumiose': ['lumioseRegionalOrder', 'lumiose_regional'],
    'lumiose-dimensions': [
      'lumioseDimensionsRegionalOrder',
      'lumiose_dimensions_regional',
    ],
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

  final specialDexes = await fetchSpecialDexes();

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
  sb.writeln('// 3. SPEZIELLE DEXE (Legi, Mythisch, Eigruppen)');
  sb.writeln('// ==========================================');
  specialDexes.forEach((key, list) {
    String varName = 'order' + key.replaceAll('-', '');
    sb.writeln('const List<int> $varName = [${list.join(', ')}];');
  });

  sb.writeln('\n// ==========================================');
  sb.writeln('// 4. ALLE BEREITGESTELLTEN DEXE (FÜR DYNAMISCHE UI)');
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

  // Spezielle Dexe zur Map hinzufügen
  specialDexes.forEach((key, list) {
    String varName = 'order' + key.replaceAll('-', '');
    String mapKey = key.replaceAll('-', '_');
    sb.writeln("  '$mapKey': $varName,");
  });

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
        await Future.delayed(const Duration(seconds: 3));
      } else if (response.statusCode == 404) {
        client.close();
        return [];
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }
  client.close();
  throw Exception('Konnte Dex $dexName nicht laden.');
}

Future<Map<String, List<int>>> fetchSpecialDexes() async {
  print(
    '\nLade Legendäre, Mythische und Eigruppen-Daten von PokeAPI... (Das dauert ca. 1 Minute)',
  );
  Map<String, List<int>> specials = {'legendary-dex': [], 'mythical-dex': []};

  final client = HttpClient();
  for (int i = 1; i <= 1025; i++) {
    bool success = false;
    for (int attempt = 1; attempt <= 3 && !success; attempt++) {
      try {
        final request = await client.getUrl(
          Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$i'),
        );
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);

          if (data['is_legendary'] == true) specials['legendary-dex']!.add(i);
          if (data['is_mythical'] == true) specials['mythical-dex']!.add(i);

          for (var eggGroup in data['egg_groups']) {
            String eggName = eggGroup['name'];
            String key = 'egg-$eggName';
            if (!specials.containsKey(key)) specials[key] = [];
            specials[key]!.add(i);
          }
          success = true;
          await Future.delayed(const Duration(milliseconds: 30));
        } else if (response.statusCode == 429) {
          await Future.delayed(const Duration(seconds: 3));
        } else {
          success = true;
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (i % 200 == 0) print('  ... $i/1025 geprüft');
  }
  client.close();
  return specials;
}
