import 'dart:convert';
import 'dart:io';

final Map<String, List<String>> _formWhitelist = {
  "172_spiky-eared": ["updated_johto_regional"],

  "25_cosplay": ["updated_hoenn_regional"],
  "25_rockstar": ["updated_hoenn_regional"],
  "25_belle": ["updated_hoenn_regional"],
  "25_popstar": ["updated_hoenn_regional"],
  "25_phd": ["updated_hoenn_regional"],
  "25_libre": ["updated_hoenn_regional"],

  "25_starter": ["kanto_regional"],
  "133_starter": ["kanto_regional"],

  "670_eternal": [
    "kalos_central_regional",
    "kalos_coastal_regional",
    "kalos_mountain_regional",
    "lumiose_regional",
  ],
};

final Map<String, int> _versionToGen = {
  'red-blue': 1,
  'yellow': 1,
  'gold-silver': 2,
  'crystal': 2,
  'ruby-sapphire': 3,
  'emerald': 3,
  'firered-leafgreen': 3,
  'diamond-pearl': 4,
  'platinum': 4,
  'heartgold-soulsilver': 4,
  'black-white': 5,
  'black-2-white-2': 5,
  'x-y': 6,
  'omega-ruby-alpha-sapphire': 6,
  'sun-moon': 7,
  'ultra-sun-ultra-moon': 7,
  'lets-go-pikachu-lets-go-eevee': 7,
  'sword-shield': 8,
  'legends-arceus': 8,
  'scarlet-violet': 9,
};

void main() async {
  print('Start Download (inkl. Whitelist-Logik)...');
  final code = await generateMasterDex(1, 1025);
  File('lib/data/national_dex_data.dart').writeAsStringSync(code);
  print('Fertig!');
}

Future<dynamic> _fetchJson(HttpClient client, String url) async {
  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200 && responseBody.trim().isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 60));
        return jsonDecode(responseBody);
      }
      if (response.statusCode == 429)
        await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  return null;
}

Future<String> generateMasterDex(int startId, int endId) async {
  final client = HttpClient();
  List<String> pokemonEntries = [];

  for (int i = startId; i <= endId; i++) {
    try {
      final speciesData = await _fetchJson(
        client,
        'https://pokeapi.co/api/v2/pokemon-species/$i',
      );
      if (speciesData == null) continue;

      String nameDe = 'Unknown';
      String nameEn = 'Unknown';
      for (var n in speciesData['names']) {
        if (n['language']['name'] == 'de') nameDe = n['name'];
        if (n['language']['name'] == 'en') nameEn = n['name'];
      }

      bool hasGenderDiff = speciesData['has_gender_differences'] ?? false;
      String speciesName = speciesData['name'];

      List<String> formObjects = [];

      for (var variety in speciesData['varieties']) {
        final pokeData = await _fetchJson(client, variety['pokemon']['url']);
        if (pokeData == null) continue;

        int varietyId = pokeData['id'];

        for (var formObj in pokeData['forms']) {
          final formData = await _fetchJson(client, formObj['url']);
          if (formData == null) continue;
          String rawFormName = formData['name'];
          String cleanForm = rawFormName
              .replaceFirst(speciesName, '')
              .replaceAll(RegExp(r'^-'), '')
              .trim();
          if (cleanForm.isEmpty) cleanForm = 'normal';

          int minGen = _versionToGen[formData['version_group']['name']] ?? 9;

          String formType = 'other';
          if (cleanForm == 'normal') {
            formType = 'normal';
            minGen = _getGenById(
              i,
            );
          } else if (cleanForm.contains('alola') ||
              cleanForm.contains('galar') ||
              cleanForm.contains('hisui') ||
              cleanForm.contains('paldea')) {
            formType = 'regional';
          } else if (cleanForm.contains('mega') || cleanForm.contains('primal')) {
            formType = 'mega';
          } else if (cleanForm.contains('gmax')) {
            formType = 'gmax';
          }

          Set<String> exclusives = (_formWhitelist["${i}_$cleanForm"] ?? [])
              .toSet();

          if (cleanForm.contains('alola')) {
            exclusives.addAll([
              'alola_regional',
              'melemele_regional',
              'akala_regional',
              'ulaula_regional',
              'poni_regional',
              'updated_alola_regional',
              'updated_melemele_regional',
              'updated_akala_regional',
              'updated_ulaula_regional',
              'updated_poni_regional',
            ]);
          } else if (cleanForm.contains('galar')) {
            exclusives.addAll([
              'galar_regional',
              'isle_of_armor_regional',
              'crown_tundra_regional',
            ]);
          } else if (cleanForm.contains('hisui')) {
            exclusives.addAll(['hisui_regional']);
          } else if (cleanForm.contains('paldea')) {
            exclusives.addAll([
              'paldea_regional',
              'kitakami_regional',
              'blueberry_regional',
            ]);
          } else if (cleanForm.contains('mega') || cleanForm.contains('primal')) {
            exclusives.addAll([
              'kalos_central_regional',
              'kalos_coastal_regional',
              'kalos_mountain_regional',
              'lumiose_regional',
              'updated_hoenn_regional',
              'letsgo_kanto_regional',
              'mega_dex',
            ]);
          } else if (cleanForm.contains('gmax')) {
            exclusives.addAll([
              'galar_regional',
              'isle_of_armor_regional',
              'crown_tundra_regional',
            ]);
          }

          String exclusiveString = exclusives.isEmpty
              ? "[]"
              : "[${exclusives.map((e) => "'$e'").join(', ')}]";

          formObjects.add(
            "PokemonForm(name: '$cleanForm', formType: '$formType', minGen: $minGen, imageId: $varietyId, exclusiveRegions: $exclusiveString, extraInfo: null)",
          );
        }
      }

      String entry =
          """
  Pokemon(
    id: $i,
    names: {'de': "${nameDe.replaceAll('"', '\\"')}", 'en': "${nameEn.replaceAll('"', '\\"')}"},
    hasGenderDifferences: $hasGenderDiff,
    forms: const [${formObjects.join(', ')}],
    extraInfo: null,
  ),""";

      pokemonEntries.add(entry);
      print('Gezogen: #$i $nameDe');
    } catch (e) {
      print('Fehler bei ID $i: $e');
    }
  }
  client.close();

  return "import '../models/pokemon.dart';\n\nfinal List<Pokemon> nationalPokemonDatabase = [\n${pokemonEntries.join('\n')}\n];";
}

int _getGenById(int id) {
  if (id <= 151) return 1;
  if (id <= 251) return 2;
  if (id <= 386) return 3;
  if (id <= 493) return 4;
  if (id <= 649) return 5;
  if (id <= 721) return 6;
  if (id <= 809) return 7;
  if (id <= 905) return 8;
  return 9;
}
