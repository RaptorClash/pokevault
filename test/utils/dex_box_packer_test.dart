import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Pokemon createDummyPokemon(int id, String name, {List<PokemonForm>? forms}) {
    return Pokemon(
      id: id,
      nameDe: name,
      nameEn: name,
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: 255,
      evolutionChainId: -1,
      eggGroups: [],
      weight: 1.0,
      speed: 10,
      forms: forms ?? [],
    );
  }

  DexDisplayEntry createEntry(int id, String name, {String? uniqueId, PokemonForm? form}) {
    return DexDisplayEntry(
      pokemon: createDummyPokemon(id, name, forms: form != null ? [form] : []),
      uniqueId: uniqueId ?? '$id',
      displaySuffix: '',
      imageUrl: 'https://example.com/$id.png',
      form: form,
    );
  }

  UserDex createDummyDex({
    String region = 'kanto',
    List<CustomBoxState>? customBoxes,
  }) {
    return UserDex(
      id: 'test_dex',
      title: 'Test Dex',
      region: region,
      includeGenders: false,
      includeRegional: true,
      includeMega: true,
      includeGMax: true,
      includeOther: false,
      isShinyDex: false,
      customBoxes: customBoxes ?? [],
    );
  }

  group('DexBoxPacker Isolated Tests (TDD)', () {
    test('generateBoxes creates standard 30-capacity boxes when separateForms is false', () {
      final entries = List.generate(
        65,
        (i) => createEntry(i + 1, 'Pokemon ${i + 1}'),
      );
      final dex = createDummyDex();

      final boxes = DexBoxPacker.generateBoxes(
        entries,
        false,
        dex,
        language: 'de',
      );

      expect(boxes.length, equals(3));
      expect(boxes[0].entries.length, equals(30));
      expect(boxes[1].entries.length, equals(30));
      expect(boxes[2].entries.length, equals(5));
      expect(boxes[0].title, contains('Box 1'));
      expect(boxes[1].title, contains('Box 2'));
      expect(boxes[2].title, contains('Box 3'));
    });

    test('generateBoxes organizes entries by regions and categories when separateForms is true', () {
    final megaForm = PokemonForm(
      name: 'mega',
      formType: 'mega',
      minGen: 6,
      imageId: 3,
      types: ['grass', 'poison'],
      exclusiveRegions: [],
    );
    final normalForm = PokemonForm(
      name: 'normal',
      formType: 'normal',
      minGen: 1,
      imageId: 3,
      types: ['grass', 'poison'],
      exclusiveRegions: [],
    );
    final entries = [
      createEntry(1, 'Bulbasaur'),
      createEntry(2, 'Ivysaur'),
      createEntry(3, 'Venusaur'),
      DexDisplayEntry(
        pokemon: createDummyPokemon(3, 'Venusaur', forms: [normalForm, megaForm]),
        uniqueId: '3_mega',
        displaySuffix: '',
        imageUrl: 'https://example.com/3_mega.png',
        form: megaForm,
      ),
    ];
      final dex = createDummyDex();

      final boxes = DexBoxPacker.generateBoxes(
        entries,
        true,
        dex,
        language: 'de',
      );

      expect(boxes.isNotEmpty, isTrue);
      // Base entries in Kanto
      expect(boxes.any((b) => b.regionKey == 'kanto'), isTrue);
      // Mega entry in Mega category
      expect(boxes.any((b) => b.title.contains('Mega')), isTrue);
    });

    test('generateBoxes preserves custom boxes and pads to dimensions', () {
      final entries = [
        createEntry(1, 'Bulbasaur'),
        createEntry(25, 'Pikachu'),
      ];
      final customBox = CustomBoxState(
        title: 'Custom Box 1',
        pokemonIds: ['1', '25'],
        regionKey: 'custom',
        columns: 6,
        rows: 5,
      );
      final dex = createDummyDex(customBoxes: [customBox]);

      final boxes = DexBoxPacker.generateBoxes(
        entries,
        false,
        dex,
        language: 'de',
      );

      expect(boxes.length, equals(1));
      expect(boxes.first.title, equals('Custom Box 1'));
      expect(boxes.first.entries.length, equals(30));
      expect(boxes.first.entries[0].uniqueId, equals('1'));
      expect(boxes.first.entries[1].uniqueId, equals('25'));
      expect(boxes.first.entries[2].uniqueId.isEmpty, isTrue);
    });

    test('generateBoxesIsolateTask executes identically to generateBoxes for isolate computing', () {
      final entries = List.generate(
        15,
        (i) => createEntry(i + 1, 'Pokemon ${i + 1}'),
      );
      final dex = createDummyDex();
      final args = GenerateBoxesArgs(entries, false, dex, 'de');

      final boxes = DexBoxPacker.generateBoxesIsolateTask(args);

      expect(boxes.length, equals(1));
      expect(boxes.first.entries.length, equals(15));
      expect(boxes.first.title, contains('Box 1'));
    });
  });
}
