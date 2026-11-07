import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Pokedex SQLite Multi-Language Schema & Data Tests', () {
    late Database db;

    setUpAll(() async {
      sqfliteFfiInit();
      final dbPath = File('assets/db/pokedex.sqlite');
      expect(dbPath.existsSync(), isTrue, reason: 'assets/db/pokedex.sqlite must exist');
      db = await databaseFactoryFfi.openDatabase(
        dbPath.absolute.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
    });

    tearDownAll(() async {
      await db.close();
    });

    test('pokemon table has all 10 official franchise language columns', () async {
      final result = await db.rawQuery('PRAGMA table_info(pokemon)');
      final columnNames = result.map((row) => row['name'].toString()).toSet();

      final requiredColumns = [
        'id',
        'name_de',
        'name_en',
        'name_fr',
        'name_es',
        'name_it',
        'name_ja',
        'name_ko',
        'name_zh_hans',
        'name_zh_hant',
      ];

      for (final col in requiredColumns) {
        expect(columnNames, contains(col), reason: 'Column $col missing in pokemon table');
      }
    });

    test('Bulbasaur (#1) has correct names across all franchise languages', () async {
      final result = await db.rawQuery('SELECT * FROM pokemon WHERE id = 1');
      expect(result.isNotEmpty, isTrue);

      final row = result.first;
      expect(row['name_de'], 'Bisasam');
      expect(row['name_en'], 'Bulbasaur');
      expect(row['name_fr'], 'Bulbizarre');
      expect(row['name_es'], 'Bulbasaur');
      expect(row['name_it'], 'Bulbasaur');
      expect(row['name_ja'], 'フシギダネ');
      expect(row['name_ko'], '이상해씨');
      expect(row['name_zh_hans'], '妙蛙种子');
      expect(row['name_zh_hant'], '妙蛙種子');
    });
  });
}
