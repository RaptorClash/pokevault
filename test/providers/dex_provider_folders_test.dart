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
      when(() => mockDb.getAllRibbons()).thenAnswer((_) async => []);
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

    // NEUER TEST FÜR DRAG & DROP
    test('reorderItem ändert die Reihenfolge in einem Ordner', () {
      provider.structure['root'] = ['item1', 'item2', 'item3'];

      // Verschiebe item1 (Index 0) nach hinten (Index 2)
      provider.reorderItem('root', 0, 2);

      // Nach dem Entfernen rücken die Elemente auf, daher landet item1 am Ende
      expect(provider.structure['root'], equals(['item2', 'item3', 'item1']));
      verify(() => mockDb.saveStructure(any())).called(greaterThan(0));
    });

    test('reorderItem mit ungültigen Indizes wirft keine Exception', () {
      provider.structure['root'] = ['item1', 'item2', 'item3'];

      // newIndex >= list.length darf nicht abstürzen
      expect(() => provider.reorderItem('root', 0, 3), returnsNormally);
      expect(() => provider.reorderItem('root', 0, -1), returnsNormally);
      expect(() => provider.reorderItem('root', -1, 1), returnsNormally);
      expect(() => provider.reorderItem('root', 3, 1), returnsNormally);
      expect(() => provider.reorderItem('nonexistent_folder', 0, 1), returnsNormally);
    });

    test('reorderItem mit gleichem Index ist No-Op', () {
      provider.structure['root'] = ['item1', 'item2', 'item3'];
      provider.reorderItem('root', 1, 1);
      expect(provider.structure['root'], equals(['item1', 'item2', 'item3']));
    });

    test('sanitizeStructure bereinigt verwaiste IDs und ordnet nicht zugeordnete Dexe root zu', () {
      final dex1 = UserDex(id: 'dex_1', title: 'Dex 1', region: 'kanto', includeGenders: false, includeRegional: false, includeMega: false, includeGMax: false, includeOther: false, isShinyDex: false, caughtIds: []);
      final dex2 = UserDex(id: 'dex_2', title: 'Dex 2', region: 'kanto', includeGenders: false, includeRegional: false, includeMega: false, includeGMax: false, includeOther: false, isShinyDex: false, caughtIds: []);
      final folderA = DexFolder(id: 'folder_a', title: 'Folder A');

      provider.userDexes = [dex1, dex2];
      provider.folders = [folderA];
      provider.structure = {
        'root': ['folder_a', 'orphaned_dex_id'],
        'folder_a': ['dex_1'],
        'folder_deleted': ['something'],
      };

      provider.sanitizeStructure();

      // folder_deleted muss entfernt worden sein
      expect(provider.structure.containsKey('folder_deleted'), isFalse);
      // orphaned_dex_id muss aus root entfernt worden sein
      expect(provider.structure['root'], isNot(contains('orphaned_dex_id')));
      // dex_2 war nirgends zugeordnet und muss in root gelandet sein
      expect(provider.structure['root'], contains('dex_2'));
      // folder_a und dex_1 müssen erhalten bleiben
      expect(provider.structure['root'], contains('folder_a'));
      expect(provider.structure['folder_a'], contains('dex_1'));
    });
  });
}
