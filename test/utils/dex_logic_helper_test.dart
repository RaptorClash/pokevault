import 'package:flutter_test/flutter_test.dart';
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
  });
}
