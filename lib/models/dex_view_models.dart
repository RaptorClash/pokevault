import 'pokemon.dart';
import '../utils/dex_logic_helper.dart';

class DexDisplayEntry {
  final Pokemon pokemon;
  final String uniqueId;
  final String displaySuffix;
  final String imageUrl;
  final PokemonForm? form;

  DexDisplayEntry({
    required this.pokemon,
    required this.uniqueId,
    required this.displaySuffix,
    required this.imageUrl,
    this.form,
  });

  PokemonForm? get resolvedForm =>
      form ?? DexLogicHelper.getEntryForm(pokemon, uniqueId);

  static final DexDisplayEntry emptyEntry = DexDisplayEntry(
    pokemon: Pokemon(
      id: -1,
      nameDe: '',
      nameEn: '',
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: -1,
      evolutionChainId: -1,
      eggGroups: [],
      weight: 0.0,
      speed: 0,
      forms: [],
    ),
    uniqueId: '',
    displaySuffix: '',
    imageUrl: '',
  );

  static DexDisplayEntry placeholderEntry([String uniqueId = 'placeholder']) => DexDisplayEntry(
    pokemon: Pokemon(
      id: -2,
      nameDe: 'Platzhalter',
      nameEn: 'Placeholder',
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: -1,
      evolutionChainId: -1,
      eggGroups: [],
      weight: 0.0,
      speed: 0,
      forms: [],
    ),
    uniqueId: uniqueId,
    displaySuffix: '',
    imageUrl: '',
  );

  bool get isPlaceholder =>
      uniqueId.startsWith('placeholder') || uniqueId.startsWith('empty_placeholder');
}

class BoxData {
  final String title;
  final String regionKey;
  final List<DexDisplayEntry> entries;
  final int crossAxisCount;

  BoxData(this.title, this.regionKey, this.entries, this.crossAxisCount);
}
