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
    registerFallbackValue(<String, List<String>>{});
    registerFallbackValue(DexFolder(id: 'dummy', title: 'dummy'));
  });

  group('DexProvider Ordner-Management', () {
    late DexProvider provider;
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

      when(() => mockDb.saveFolder(any())).thenAnswer((_) async {});
      when(() => mockDb.deleteFolder(any())).thenAnswer((_) async {});
      when(() => mockDb.saveStructure(any())).thenAnswer((_) async {});

      provider = DexProvider(databaseService: mockDb);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('createFolder legt Ordner an und platziert ihn im root', () {
      provider.createFolder('Shinies', 'root');

      expect(provider.folders.length, equals(1));
      expect(provider.folders.first.title, equals('Shinies'));
      expect(provider.structure['root'], contains(provider.folders.first.id));
      verify(() => mockDb.saveFolder(any())).called(1);
    });

    test('renameFolder aktualisiert den Titel korrekt', () {
      provider.createFolder('Alte Dexe', 'root');
      final folderId = provider.folders.first.id;

      provider.renameFolder(folderId, 'Neue Dexe');

      expect(provider.folders.first.title, equals('Neue Dexe'));
      verify(() => mockDb.saveFolder(any())).called(2);
    });

    test('moveItem verschiebt ein Item von root in einen Ordner', () {
      provider.createFolder('Zielordner', 'root');
      final folderId = provider.folders.first.id;

      provider.structure['root']!.add('dex_123');

      provider.moveItem('dex_123', folderId);

      expect(provider.structure['root'], isNot(contains('dex_123')));
      expect(provider.structure[folderId], contains('dex_123'));
      verify(() => mockDb.saveStructure(any())).called(greaterThan(0));
    });

    test('isDescendant erkennt verschachtelte Ordner korrekt', () {
      provider.structure = {
        'root': ['folder_1'],
        'folder_1': ['folder_2'],
        'folder_2': ['folder_3'],
      };

      expect(provider.isDescendant('folder_1', 'folder_3'), isTrue);
      expect(provider.isDescendant('folder_3', 'folder_1'), isFalse);
    });
  });
}
