import 'pokemon.dart';

class DexDisplayEntry {
  final Pokemon pokemon;
  final String uniqueId;
  final String displaySuffix;
  final String imageUrl;

  DexDisplayEntry({
    required this.pokemon,
    required this.uniqueId,
    required this.displaySuffix,
    required this.imageUrl,
  });
}

class BoxData {
  final String title;
  final String regionKey;
  final List<DexDisplayEntry> entries;
  final int crossAxisCount;

  BoxData(this.title, this.regionKey, this.entries, this.crossAxisCount);
}