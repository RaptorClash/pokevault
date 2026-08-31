import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/user_dex.dart';

void main() {
  group('UserDex Model Tests', () {
    test('toMap und fromMap wandeln Daten für SQLite korrekt um', () {
      final originalDex = UserDex(
        id: 'dex_123',
        title: 'Mein Kanto Dex',
        region: 'kanto',
        includeGenders: true,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
      );

      final map = originalDex.toMap();

      expect(map['id'], 'dex_123');
      expect(map['title'], 'Mein Kanto Dex');
      expect(map['is_shiny_dex'], 1);
      expect(map['include_genders'], 1);
      expect(map['include_regional'], 0);

      final restoredDex = UserDex.fromMap(map);

      expect(restoredDex.id, 'dex_123');
      expect(restoredDex.title, 'Mein Kanto Dex');
      expect(restoredDex.isShinyDex, isTrue);
      expect(restoredDex.includeRegional, isFalse);
    });

    test('toJson und fromJson speichern und laden Listen für Backups', () {
      final originalDex = UserDex(
        id: 'dex_456',
        title: 'National Backup',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: true,
        isShinyDex: false,
        caughtIds: ['1_normal', '25_normal'],
        ignoredIds: ['150_normal'],
        shinyIds: [],
      );

      final json = originalDex.toJson();
      final restoredDex = UserDex.fromJson(json);

      expect(restoredDex.caughtIds.length, 2);
      expect(restoredDex.caughtIds, contains('25_normal'));
      expect(restoredDex.ignoredIds, contains('150_normal'));
      expect(restoredDex.includeMega, isTrue);
    });
  });
}
