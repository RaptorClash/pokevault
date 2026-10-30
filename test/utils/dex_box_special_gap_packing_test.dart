import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/box_sequence_manager.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  group('Special Box Gap Packing & Layout Cleanliness Tests (TDD)', () {
    late Pokemon rattata;
    late Pokemon raichu;
    late Pokemon sandshrew;
    late Pokemon vulpix;
    late Pokemon diglett;
    late Pokemon meowth;
    late Pokemon geodude;
    late Pokemon grimer;
    late Pokemon exeggutor;
    late Pokemon marowak;
    late List<Pokemon> pokemonList;
    late List<DexDisplayEntry> displayEntries;

    setUp(() {
      Pokemon createPoke(int id, String name, String form) {
        return Pokemon(
          id: id,
          nameDe: name,
          nameEn: name,
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: id,
          eggGroups: ['field'],
          weight: 5.0,
          speed: 60,
          forms: [
            PokemonForm(
              name: 'normal',
              formType: 'normal',
              minGen: 1,
              imageId: id,
              types: ['normal'],
              exclusiveRegions: [],
            ),
            PokemonForm(
              name: form,
              formType: 'regional',
              minGen: 7,
              imageId: id + 10000,
              types: ['dark'],
              exclusiveRegions: [],
            ),
          ],
        );
      }

      rattata = createPoke(19, 'Rattfratz', 'alola');
      raichu = createPoke(26, 'Raichu', 'alola');
      sandshrew = createPoke(27, 'Sandan', 'alola');
      vulpix = createPoke(37, 'Vulpix', 'alola');
      diglett = createPoke(50, 'Digda', 'alola');
      meowth = createPoke(52, 'Mauzi', 'alola');
      geodude = createPoke(74, 'Kleinstein', 'alola');
      grimer = createPoke(88, 'Sleima', 'alola');
      exeggutor = createPoke(103, 'Kokowei', 'alola');
      marowak = createPoke(105, 'Knogga', 'alola');

      pokemonList = [
        rattata,
        raichu,
        sandshrew,
        vulpix,
        diglett,
        meowth,
        geodude,
        grimer,
        exeggutor,
        marowak,
      ];

      displayEntries = pokemonList.map((p) {
        final form = p.forms.last;
        return DexDisplayEntry(
          pokemon: p,
          uniqueId: '${p.id}_special_${p.id + 100}_trade_kanto_alola',
          displaySuffix: ' (Alola) (Tausche - Let\'s Go)',
          imageUrl: 'https://img.test/${form.imageId}.png',
          form: form,
        );
      }).toList();
    });

    test('isSpecialBoxTitle identifies trade, gift, N, form, and orre boxes correctly', () {
      expect(DexLogicHelper.isSpecialBoxTitle('Kanto Tausche 2'), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle('Kanto Trades'), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle('Johto Geschenke 1'), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle('Sinnoh Gifts'), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle("N's Pokémon"), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle("Box 1 (Formen)"), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle("Box 2 (Forms 2)"), isTrue);
      expect(DexLogicHelper.isSpecialBoxTitle("Orre Tausche"), isTrue);

      expect(DexLogicHelper.isSpecialBoxTitle('Kanto (1-30)'), isFalse);
      expect(DexLogicHelper.isSpecialBoxTitle('Box 1'), isFalse);
      expect(DexLogicHelper.isSpecialBoxTitle('National 01'), isFalse);
    });

    test('Special boxes with gaps (empty entries in rows 2 & 3) are packed sequentially without middle holes', () {
      // Simulating Bild 1:
      // Row 1 (slots 0..5) populated with 6 cards
      // Rows 2 & 3 (slots 6..17) empty
      // Rows 4 & 5 (slots 18..21) populated with 4 cards
      final boxEntriesWithGap = <String>[];
      // Row 1: 6 entries
      for (int i = 0; i < 6; i++) {
        boxEntriesWithGap.add(displayEntries[i].uniqueId);
      }
      // Rows 2 & 3: 12 empty slots
      for (int i = 0; i < 12; i++) {
        boxEntriesWithGap.add('');
      }
      // Row 4: 4 entries
      for (int i = 6; i < 10; i++) {
        boxEntriesWithGap.add(displayEntries[i].uniqueId);
      }
      // Remainder up to 30 capacity: empty
      while (boxEntriesWithGap.length < 30) {
        boxEntriesWithGap.add('');
      }

      final customBox = CustomBoxState(
        title: 'Kanto Tausche 2',
        pokemonIds: boxEntriesWithGap,
        columns: 6,
        rows: 5,
        regionKey: 'kanto',
      );

      final liveDex = UserDex(
        id: 'test_dex_special_box',
        title: 'Test Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        customBoxes: [customBox],
      );

      final generatedBoxes = DexLogicHelper.generateBoxes(
        displayEntries,
        true,
        liveDex,
      );

      expect(generatedBoxes.length, 1);
      final box = generatedBoxes.first;
      expect(box.title, 'Kanto Tausche 2');

      // All 10 valid entries must be packed sequentially in slots 0..9
      for (int i = 0; i < 10; i++) {
        expect(
          box.entries[i].uniqueId,
          displayEntries[i].uniqueId,
          reason: 'Slot $i should contain pokemon ${displayEntries[i].pokemon.id} packed without gap',
        );
      }

      // Slots 10..29 should be empty entries at the END of the box, never in the middle
      for (int i = 10; i < 30; i++) {
        expect(
          box.entries[i].uniqueId,
          '',
          reason: 'Slot $i should be trailing empty slot',
        );
      }
    });

    test('Special box resolves migrated special entries instead of failing and creating empty holes', () {
      // Suppose an entry ID was stored as old normal trade form (e.g. before Alola normalization):
      // 19_special_292_trade_kanto_normal
      // And in entries we have: 19_special_140_trade_kanto_alola
      final storedIds = [
        '19_special_292_trade_kanto_normal__1234_0',
        '26_special_298_trade_kanto_normal__1234_1',
      ];
      while (storedIds.length < 30) {
        storedIds.add('');
      }

      final customBox = CustomBoxState(
        title: 'Kanto Tausche 2',
        pokemonIds: storedIds,
        columns: 6,
        rows: 5,
        regionKey: 'kanto',
      );

      final liveDex = UserDex(
        id: 'test_dex_resolve_special',
        title: 'Test Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        customBoxes: [customBox],
      );

      final generatedBoxes = DexLogicHelper.generateBoxes(
        displayEntries,
        true,
        liveDex,
      );

      final box = generatedBoxes.first;
      expect(box.entries[0].pokemon.id, 19);
      expect(box.entries[0].form?.name, 'alola');
      expect(box.entries[1].pokemon.id, 26);
      expect(box.entries[1].form?.name, 'alola');
    });

    test('BoxSequenceManager.packSpecialBoxes compacts customBoxes in place', () {
      final customBox = CustomBoxState(
        title: 'Kanto Tausche 2',
        pokemonIds: ['p1', '', '', '', 'p2', 'p3'],
        columns: 6,
        rows: 1,
        regionKey: 'kanto',
      );

      final dex = UserDex(
        id: 'dex_pack',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        customBoxes: [customBox],
      );

      BoxSequenceManager.packSpecialBoxes(dex);

      expect(customBox.pokemonIds, ['p1', 'p2', 'p3', '', '', '']);
    });

    test('DexLogicHelper.migrateCustomBoxInstances packs special boxes and returns true', () {
      final customBox = CustomBoxState(
        title: 'Kanto Tausche 2',
        pokemonIds: ['p1__1_0', '', '', '', 'p2__1_1', 'p3__1_2'],
        columns: 6,
        rows: 1,
        regionKey: 'kanto',
      );

      final dex = UserDex(
        id: 'dex_pack_migrated',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        customBoxes: [customBox],
      );

      final migrated = DexLogicHelper.migrateCustomBoxInstances(dex);
      expect(migrated, isTrue);
      expect(customBox.pokemonIds, ['p1__1_0', 'p2__1_1', 'p3__1_2', '', '', '']);
    });

    test('BoxSequenceManager.packSpecialBoxes identifies special boxes by _special_ IDs even with custom title', () {
      final customBox = CustomBoxState(
        title: 'Meine Sammlung',
        pokemonIds: [
          '19_special_140_trade_kanto_alola__1_0',
          '',
          '',
          '74_special_141_trade_kanto_alola__1_1',
          '',
          '',
        ],
        columns: 6,
        rows: 1,
        regionKey: 'kanto',
      );

      final dex = UserDex(
        id: 'dex_custom_title_special',
        title: 'Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        customBoxes: [customBox],
      );

      final changed = BoxSequenceManager.packSpecialBoxes(dex);
      expect(changed, isTrue);
      expect(customBox.pokemonIds, [
        '19_special_140_trade_kanto_alola__1_0',
        '74_special_141_trade_kanto_alola__1_1',
        '',
        '',
        '',
        '',
      ]);
    });
  });
}
