import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/pokemon.dart';

void main() {
  group('Pokemon Multi-Language Tests', () {
    final sampleMap = {
      'id': 1,
      'name_de': 'Bisasam',
      'name_en': 'Bulbasaur',
      'name_fr': 'Bulbizarre',
      'name_es': 'Bulbasaur',
      'name_it': 'Bulbasaur',
      'name_ja': 'フシギダネ',
      'name_ko': '이상해씨',
      'name_zh_hans': '妙蛙种子',
      'name_zh_hant': '妙蛙種子',
      'has_gender_differences': 0,
      'gender_rate': 1,
      'capture_rate': 45,
      'evolution_chain_id': 1,
      'egg_groups': 'monster,plant',
      'weight': 6.9,
      'speed': 45,
      'catch_rate_tags': '',
    };

    test('Pokemon.fromMap populates all 10 franchise names', () {
      final p = Pokemon.fromMap(sampleMap);

      expect(p.id, 1);
      expect(p.getName('de'), 'Bisasam');
      expect(p.getName('en'), 'Bulbasaur');
      expect(p.getName('fr'), 'Bulbizarre');
      expect(p.getName('es'), 'Bulbasaur');
      expect(p.getName('it'), 'Bulbasaur');
      expect(p.getName('ja'), 'フシギダネ');
      expect(p.getName('ko'), '이상해씨');
      expect(p.getName('zh-Hans'), '妙蛙种子');
      expect(p.getName('zh_hans'), '妙蛙种子');
      expect(p.getName('zh-Hant'), '妙蛙種子');
      expect(p.getName('zh_hant'), '妙蛙種子');
    });

    test('backward compatibility: nameDe and nameEn getters work directly', () {
      final p = Pokemon.fromMap(sampleMap);
      expect(p.nameDe, 'Bisasam');
      expect(p.nameEn, 'Bulbasaur');
    });

    test('fallback to en when requested language is missing', () {
      final partialMap = {
        'id': 25,
        'name_de': 'Pikachu',
        'name_en': 'Pikachu',
        // other names missing
      };
      final p = Pokemon.fromMap(partialMap);

      expect(p.getName('fr'), 'Pikachu');
      expect(p.getName('ja'), 'Pikachu');
      expect(p.getName('pt'), 'Pikachu');
    });

    test('fallback to Unknown when all names are missing', () {
      final emptyMap = {'id': 9999};
      final p = Pokemon.fromMap(emptyMap);

      expect(p.getName('ja'), 'Unknown');
      expect(p.nameDe, 'Unknown');
      expect(p.nameEn, 'Unknown');
    });
  });
}
