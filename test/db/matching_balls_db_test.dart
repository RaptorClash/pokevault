import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = '${Directory.current.path}/assets/db/pokedex.sqlite';
    if (!File(dbPath).existsSync()) {
      fail('Datenbank nicht gefunden! Führe zuerst build_database.py aus.');
    }

    db = await databaseFactory.openDatabase(dbPath);
  });

  tearDownAll(() async {
    await db.close();
  });

  Future<Map<String, dynamic>?> getEntry(String uniqueId) async {
    final maps = await db.query(
      'matching_balls',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> checkValid(String id) async {
    final entry = await getEntry(id);
    expect(entry, isNotNull, reason: 'ID $id fehlt komplett in der Datenbank.');
    expect(
      entry!['normal_balls'],
      isNot('any_ball'),
      reason: '$id hat fälschlicherweise "any_ball" als Wert.',
    );
    expect(
      entry['shiny_balls'],
      isNot('any_ball'),
      reason: '$id hat fälschlicherweise "any_ball" als Wert.',
    );
  }

  group('Matching Balls - Striktes Excel-Binding & Edge Cases', () {
    test('1. Standard Basis-Pokémon (aus der Excel) sind vorhanden', () async {
      final ids = [
        '1_normal',
        '25_normal',
        '133_normal',
        '150_normal',
        '248_normal',
        '448_normal',
      ];
      for (var id in ids) {
        await checkValid(id);
      }
    });

    test(
      '2. Falsche "Mega"-Erkennungen (Yanmega, Meganie) wurden repariert',
      () async {
        final meganiumMega = await getEntry('154_mega');
        expect(
          meganiumMega,
          isNull,
          reason:
              'Meganie wurde fälschlicherweise als Mega erkannt! Hast du das neue Python-Skript ausgeführt?',
        );
        await checkValid('154_normal');

        final yanmegaMega = await getEntry('469_mega');
        expect(
          yanmegaMega,
          isNull,
          reason:
              'Yanmega wurde fälschlicherweise als Mega erkannt! Hast du das neue Python-Skript ausgeführt?',
        );
        await checkValid('469_normal');
      },
    );

    test('3. Echte Mega-Entwicklungen funktionieren', () async {
      final ids = [
        '3_mega',
        '6_mega-x',
        '6_mega-y',
        '94_mega',
        '115_mega',
        '384_mega',
        '448_mega',
      ];
      for (var id in ids) {
        await checkValid(id);
      }
    });

    test('4. Regionale Formen (Alola, Galar, Hisui, Paldea)', () async {
      final ids = ['37_alola', '52_galar', '58_hisui', '194_paldea'];
      for (var id in ids) {
        await checkValid(id);
      }
    });

    test('5. Spezielle Formen & Geschlechter-Splits', () async {
      final ids = [
        '669_red',
        '669_blue',
        '658_battle-bond',
        '741_baile',
        '741_pom-pom',
        '479_wash',
        '479_heat',
        '3_m',
        '3_f',
        '678_m',
        '678_f',
        '876_m',
        '876_f',
      ];
      for (var id in ids) {
        await checkValid(id);
      }
    });

    test('6. Spezifische Vivillon und Pokusan (Alcremie) Muster', () async {
      final ids = [
        '666_meadow',
        '666_icy-snow',
        '666_ocean',
        '666_poke-ball',
        '869_ruby-cream',
        '869_matcha-cream',
        '869_rainbow-swirl',
      ];
      for (var id in ids) {
        await checkValid(id);
      }
    });

    test('7. Hardcoded Typ-Overrides (Arceus & Amigento)', () async {
      final arceusFire = await getEntry('493_fire');
      expect(arceusFire!['normal_balls'], contains('fast_ball'));

      final amigentoSteel = await getEntry('773_steel');
      expect(amigentoSteel!['normal_balls'], contains('heavy_ball'));
    });

    test(
      '8. Unmapped Pokémon (z.B. Raupy) erhalten den Fallback any_ball',
      () async {
        final caterpie = await getEntry('10_normal');
        expect(caterpie, isNotNull);
        expect(
          caterpie!['normal_balls'],
          equals('any_ball'),
          reason: 'Raupy sollte strikt auf any_ball stehen.',
        );

        final victini = await getEntry('494_normal');
        expect(victini, isNotNull);
        expect(
          victini!['normal_balls'],
          equals('any_ball'),
          reason: 'Victini sollte strikt auf any_ball stehen.',
        );
      },
    );
  });
}
