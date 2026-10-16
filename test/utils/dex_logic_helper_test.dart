import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

void main() {
  group('DexLogicHelper Tests', () {
    test('getMaxGenForDex gibt die richtige Maximal-Generation zurück', () {
      expect(DexLogicHelper.getMaxGenForDex('kanto'), equals(1));
      expect(DexLogicHelper.getMaxGenForDex('johto'), equals(2));
      expect(DexLogicHelper.getMaxGenForDex('galar'), equals(8));
      expect(DexLogicHelper.getMaxGenForDex('paldea'), equals(9));
      expect(DexLogicHelper.getMaxGenForDex('national_overall'), equals(99));
    });

    test('chunkList teilt lange Listen korrekt in Boxen auf', () {
      final list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

      final chunks3 = DexLogicHelper.chunkList(list, 3);

      expect(chunks3.length, equals(4));
      expect(chunks3.first.length, equals(3));
      expect(chunks3.last.length, equals(1));
      expect(chunks3.last.first, equals(10));

      final chunks5 = DexLogicHelper.chunkList(list, 5);
      expect(chunks5.length, equals(2)); // Genau 2 Boxen
      expect(chunks5.first, equals([1, 2, 3, 4, 5]));
    });

    test('getFormDisplayName verarbeitet Strings richtig (Fallback-Test)', () {
      expect(DexLogicHelper.getFormDisplayName('mega'), equals('Mega'));
      expect(DexLogicHelper.getFormDisplayName('alola'), equals('Alola'));
      expect(DexLogicHelper.getFormDisplayName(''), equals(''));
    });

    group('getBaseId Tests', () {
      test('getBaseId returns empty string for empty input', () {
        expect(DexLogicHelper.getBaseId(''), equals(''));
      });

      test('getBaseId returns same string when no separator is present', () {
        expect(DexLogicHelper.getBaseId('1_normal'), equals('1_normal'));
        expect(DexLogicHelper.getBaseId('pikachu'), equals('pikachu'));
      });

      test('getBaseId extracts base ID correctly when __ suffix is present', () {
        expect(DexLogicHelper.getBaseId('1_normal__1728412345_123_0'), equals('1_normal'));
        expect(DexLogicHelper.getBaseId('25_pikachu__timestamp_hash_4'), equals('25_pikachu'));
      });
    });

    group('isPokemonCaught Normalization Tests', () {
      UserDex createTestDex({
        List<String> caughtIds = const [],
        List<String> shinyIds = const [],
        List<String> alphaIds = const [],
      }) {
        return UserDex(
          id: 'test_dex',
          title: 'Test Dex',
          region: 'kanto',
          includeGenders: false,
          includeRegional: false,
          includeMega: false,
          includeGMax: false,
          includeOther: false,
          isShinyDex: false,
          caughtIds: List.from(caughtIds),
          shinyIds: List.from(shinyIds),
          alphaIds: List.from(alphaIds),
        );
      }

      test('isPokemonCaught returns false for empty uniqueId', () {
        final dex = createTestDex(caughtIds: ['1_normal']);
        expect(DexLogicHelper.isPokemonCaught(dex, ''), isFalse);
      });

      test('isPokemonCaught returns true when base ID matches directly in caughtIds', () {
        final dex = createTestDex(caughtIds: ['1_normal']);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isTrue);
      });

      test('isPokemonCaught returns true for primary composite instance ID when base ID is caught', () {
        final dex = createTestDex(caughtIds: ['1_normal']);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__1728412345_123_0'), isTrue);
      });

      test('isPokemonCaught returns true for composite instance ID when exact instance ID is in caughtIds', () {
        final dex = createTestDex(caughtIds: ['1_normal__1728412345_123_0']);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__1728412345_123_0'), isTrue);
      });

      test('isPokemonCaught returns true for base ID when only composite instance ID is in caughtIds', () {
        final dex = createTestDex(caughtIds: ['1_normal__1728412345_123_0']);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isTrue);
      });

      test('isPokemonCaught returns false when Pokémon is not caught', () {
        final dex = createTestDex(caughtIds: ['4_normal', '7_normal']);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__1728412345_123_0'), isFalse);
      });

      test('isPokemonShiny normalizes base IDs and composite instance IDs', () {
        final dex = createTestDex(shinyIds: ['25_normal']);
        expect(DexLogicHelper.isPokemonShiny(dex, ''), isFalse);
        expect(DexLogicHelper.isPokemonShiny(dex, '25_normal'), isTrue);
        expect(DexLogicHelper.isPokemonShiny(dex, '25_normal__999_888_0'), isTrue);
        expect(DexLogicHelper.isPokemonShiny(dex, '1_normal'), isFalse);

        final dexWithInstance = createTestDex(shinyIds: ['133_normal__inst1']);
        expect(DexLogicHelper.isPokemonShiny(dexWithInstance, '133_normal'), isTrue);
        expect(DexLogicHelper.isPokemonShiny(dexWithInstance, '133_normal__inst1'), isTrue);
        // An un-shined instance of the same Pokemon remains normal
        expect(DexLogicHelper.isPokemonShiny(dexWithInstance, '133_normal__inst2'), isFalse);
      });

      test('isPokemonAlpha normalizes base IDs and composite instance IDs', () {
        final dex = createTestDex(alphaIds: ['150_normal']);
        expect(DexLogicHelper.isPokemonAlpha(dex, ''), isFalse);
        expect(DexLogicHelper.isPokemonAlpha(dex, '150_normal'), isTrue);
        expect(DexLogicHelper.isPokemonAlpha(dex, '150_normal__777_666_0'), isTrue);
        expect(DexLogicHelper.isPokemonAlpha(dex, '1_normal'), isFalse);

        final dexWithInstance = createTestDex(alphaIds: ['151_normal__inst2']);
        expect(DexLogicHelper.isPokemonAlpha(dexWithInstance, '151_normal'), isTrue);
        expect(DexLogicHelper.isPokemonAlpha(dexWithInstance, '151_normal__inst2'), isTrue);
      });

      test('in custom boxes, distinct instances of the same species are independent and do not inherit caught status from baseId', () {
        final dex = createTestDex(caughtIds: ['1_normal', '1_normal__inst1']);
        dex.customBoxes = [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1_normal__inst1', '1_normal__inst2']),
        ];

        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal__inst2'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isTrue);
      });

      test('in custom boxes, primary instance is caught when baseId is caught, but duplicate instance is not caught', () {
        final dex = createTestDex(caughtIds: ['25_normal']);
        dex.customBoxes = [
          CustomBoxState(title: 'Box 1', pokemonIds: ['25_normal__inst1', '25_normal__inst2']),
        ];

        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal__inst2'), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, '25_normal'), isTrue);
      });

      test('in custom boxes, shiny and alpha instances are evaluated independently', () {
        final dex = createTestDex(
          shinyIds: ['1_normal', '1_normal__inst1'],
          alphaIds: ['1_normal', '1_normal__inst1'],
        );
        dex.customBoxes = [
          CustomBoxState(title: 'Box 1', pokemonIds: ['1_normal__inst1', '1_normal__inst2']),
        ];

        expect(DexLogicHelper.isPokemonShiny(dex, '1_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonShiny(dex, '1_normal__inst2'), isFalse);

        expect(DexLogicHelper.isPokemonAlpha(dex, '1_normal__inst1'), isTrue);
        expect(DexLogicHelper.isPokemonAlpha(dex, '1_normal__inst2'), isFalse);
      });

      test('preserves existing dex with 680 caught base IDs and composite instance IDs in custom boxes', () {
        final caught = List.generate(680, (i) => '${i + 1}_normal');
        final boxSlots = List.generate(1020, (i) => '${i + 1}_normal__timestamp_$i');
        final dex = createTestDex(caughtIds: caught);
        dex.customBoxes = [
          CustomBoxState(title: 'Box 1', pokemonIds: boxSlots),
        ];

        // Caught count matches exactly 680
        expect(DexLogicHelper.getCaughtCount(dex), equals(680));
        // Caught items evaluate to true
        expect(DexLogicHelper.isPokemonCaught(dex, boxSlots[0]), isTrue);
        expect(DexLogicHelper.isPokemonCaught(dex, boxSlots[679]), isTrue);
        // Uncaught items evaluate to false
        expect(DexLogicHelper.isPokemonCaught(dex, boxSlots[680]), isFalse);
        expect(DexLogicHelper.isPokemonCaught(dex, boxSlots[1019]), isFalse);
      });
    });
  });
}
