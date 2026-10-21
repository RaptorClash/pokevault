import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': 27});
  });

  group('Gender Differences Service Tests (TDD)', () {
    test('Liefert deutsche und englische Beschreibung für Pokémon mit Geschlechtsunterschieden (Bisaflor #3)', () async {
      final diff = await DatabaseService.instance.getGenderDifference(3);
      expect(diff, isNotNull);
      expect(diff!['de'], contains('Bisaflor'));
      expect(diff['en'], contains('flower'));
    });

    test('Liefert korrekte Beschreibungen für Pikachu (#25)', () async {
      final diff = await DatabaseService.instance.getGenderDifference(25);
      expect(diff, isNotNull);
      expect(diff!['de'], contains('Schwanz'));
      expect(diff['en'], contains('tail'));
    });

    test('Liefert null für Pokémon OHNE Geschlechtsunterschiede (Glumanda #4)', () async {
      final diff = await DatabaseService.instance.getGenderDifference(4);
      expect(diff, isNull);
    });

    test('Liefert null für ungültige / negative Pokémon-ID', () async {
      final diff = await DatabaseService.instance.getGenderDifference(-99);
      expect(diff, isNull);
    });

    test('Index idx_gender_differences_pokemon_id existiert in der Referenz-Datenbank', () async {
      final db = await DatabaseService.instance.appDatabase;
      final rawIndices = await db.rawQuery("PRAGMA index_list('gender_differences')");
      final indexNames = rawIndices.map((row) => row['name'] as String).toList();
      expect(indexNames, contains('idx_gender_differences_pokemon_id'));
    });
  });
}
