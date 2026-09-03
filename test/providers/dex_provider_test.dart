import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/user_dex.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      UserDex(
        id: 'dummy',
        title: 'dummy',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      ),
    );
    registerFallbackValue(<String, List<String>>{});
  });

  group('DexProvider Tests mit Mock DB', () {
    late DexProvider dexProvider;
    late MockDatabaseService mockDb;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseService();

      when(() => mockDb.getAllPokemon()).thenAnswer((_) async => []);
      when(() => mockDb.getAllDexOrders()).thenAnswer((_) async => {});
      when(() => mockDb.getBallUrls()).thenAnswer((_) async => {});
      when(() => mockDb.getAllUserDexes()).thenAnswer((_) async => []);
      when(() => mockDb.getAllFolders()).thenAnswer((_) async => []);
      when(() => mockDb.getStructure()).thenAnswer((_) async => {'root': []});

      when(() => mockDb.saveUserDex(any())).thenAnswer((_) async {});
      when(() => mockDb.saveStructure(any())).thenAnswer((_) async {});
      when(() => mockDb.deleteUserDex(any())).thenAnswer((_) async {});

      dexProvider = DexProvider(databaseService: mockDb);

      await Future.delayed(const Duration(milliseconds: 100));
    });

    test(
      'createDex fügt einen neuen Dex hinzu und speichert in der Struktur',
      () {
        expect(dexProvider.userDexes, isEmpty);

        dexProvider.createDex(
          'Test Dex',
          'kanto',
          false,
          false,
          false,
          false,
          false,
          false,
          'root',
        );

        expect(dexProvider.userDexes.length, equals(1));
        expect(dexProvider.userDexes.first.title, equals('Test Dex'));

        expect(dexProvider.structure['root'], isNotEmpty);
        expect(
          dexProvider.structure['root']!.first,
          equals(dexProvider.userDexes.first.id),
        );

        verify(() => mockDb.saveUserDex(any())).called(1);
        verify(() => mockDb.saveStructure(any())).called(1);
      },
    );

    test('deleteDex entfernt den Dex aus der Liste und der Struktur', () {
      dexProvider.createDex(
        'To Be Deleted',
        'kanto',
        false,
        false,
        false,
        false,
        false,
        false,
        'root',
      );
      final dexId = dexProvider.userDexes.first.id;

      dexProvider.deleteDex(dexId);

      expect(dexProvider.userDexes, isEmpty);
      expect(dexProvider.structure['root'], isEmpty);

      verify(() => mockDb.deleteUserDex(dexId)).called(1);
    });
  });
}
