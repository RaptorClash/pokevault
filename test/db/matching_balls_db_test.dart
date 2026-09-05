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

  // Hilfsmethode: Prüft, ob mindestens ein Eintrag existiert, der auf ein Muster passt
  Future<void> checkPatternExists(String pattern, String description) async {
    final maps = await db.query(
      'matching_balls',
      where: 'unique_id LIKE ?',
      whereArgs: [pattern],
      limit: 1,
    );
    expect(
      maps.isNotEmpty,
      isTrue,
      reason:
          '$description fehlt komplett in der Datenbank! (Pattern: $pattern)',
    );
  }

  group('Matching Balls - Robuste Pattern-Tests', () {
    test('1. Basis-Pokémon sind vorhanden', () async {
      await checkPatternExists('1_normal', 'Bisasam');
      await checkPatternExists('25_normal', 'Pikachu');
      await checkPatternExists('150_normal', 'Mewtu');
    });

    test('2. Mega-Entwicklungen werden geparst', () async {
      // Prüft, ob irgendein Pokémon das Suffix _mega erhalten hat
      await checkPatternExists('%_mega%', 'Mindestens eine Mega-Entwicklung');
    });

    test('3. Regionale Formen werden geparst', () async {
      await checkPatternExists('%_alola', 'Mindestens eine Alola-Form');
      await checkPatternExists('%_galar', 'Mindestens eine Galar-Form');
      await checkPatternExists('%_hisui', 'Mindestens eine Hisui-Form');
      await checkPatternExists('%_paldea', 'Mindestens eine Paldea-Form');
    });

    test('4. Geschlechter-Splits werden geparst', () async {
      // Prüft, ob irgendein Pokémon einen Eintrag für weiblich (_f) hat
      await checkPatternExists('%_f', 'Mindestens eine weibliche Form');
    });

    test('5. Spezifische Muster (Vivillon & Pokusan) werden geparst', () async {
      await checkPatternExists(
        '666_%',
        'Mindestens ein Vivillon-Muster (666_)',
      );
      await checkPatternExists('869_%', 'Mindestens ein Pokusan-Muster (869_)');
    });

    test('6. Hardcoded Typ-Overrides (Arceus & Amigento) existieren', () async {
      // Diese sind im Python-Skript hartcodiert und MÜSSEN existieren
      final arceusFire = await db.query(
        'matching_balls',
        where: 'unique_id = ?',
        whereArgs: ['493_fire'],
      );
      expect(arceusFire.isNotEmpty, isTrue, reason: 'Arceus (Feuer) fehlt.');
      expect(arceusFire.first['normal_balls'], contains('fast_ball'));

      final amigentoSteel = await db.query(
        'matching_balls',
        where: 'unique_id = ?',
        whereArgs: ['773_steel'],
      );
      expect(
        amigentoSteel.isNotEmpty,
        isTrue,
        reason: 'Amigento (Stahl) fehlt.',
      );
      expect(amigentoSteel.first['normal_balls'], contains('heavy_ball'));
    });
  });
}
