import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/user_dex.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockFileSelectorPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FileSelectorPlatform {
  XFile? mockFileToReturn;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    return mockFileToReturn;
  }
}

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
    registerFallbackValue(DexFolder(id: 'dummy', title: 'dummy'));
    registerFallbackValue(<String, List<String>>{});
  });

  group('DexProvider Actions Tests', () {
    late DexProvider provider;
    late MockDatabaseService mockDb;
    late MockFileSelectorPlatform mockFileSelector;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseService();
      mockFileSelector = MockFileSelectorPlatform();
      FileSelectorPlatform.instance = mockFileSelector;

      when(() => mockDb.getAllPokemon()).thenAnswer((_) async => []);
      when(() => mockDb.getAllDexOrders()).thenAnswer((_) async => {});
      when(() => mockDb.getBallUrls()).thenAnswer((_) async => {});
      when(() => mockDb.getAllRibbons()).thenAnswer((_) async => []);
      when(() => mockDb.getAllUserDexes()).thenAnswer((_) async => []);
      when(() => mockDb.getAllFolders()).thenAnswer((_) async => []);
      when(() => mockDb.getStructure()).thenAnswer((_) async => {'root': []});

      when(() => mockDb.saveUserDex(any())).thenAnswer((_) async {});
      when(() => mockDb.deleteUserDex(any())).thenAnswer((_) async {});
      when(() => mockDb.saveFolder(any())).thenAnswer((_) async {});
      when(() => mockDb.deleteFolder(any(), recursive: any(named: 'recursive'))).thenAnswer((_) async {});
      when(() => mockDb.saveStructure(any())).thenAnswer((_) async {});
      when(
        () => mockDb.savePokemonStatus(
          any(),
          any(),
          isCaught: any(named: 'isCaught'),
          isShiny: any(named: 'isShiny'),
          isIgnored: any(named: 'isIgnored'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockDb.clearUserData()).thenAnswer((_) async {});

      provider = DexProvider(databaseService: mockDb);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('updateDex aktualisiert die Eigenschaften des Dex und speichert in DB', () {
      provider.createDex('Original Title', 'kanto', false, false, false, false, false, false, 'root');
      final dexId = provider.userDexes.first.id;

      provider.updateDex(
        dexId,
        'Updated Title',
        true, // includeGenders
        true, // includeRegional
        true, // includeMega
        true, // includeGMax
        true, // includeOther
        true, // isShinyDex
      );

      final updated = provider.userDexes.first;
      expect(updated.title, equals('Updated Title'));
      expect(updated.includeGenders, isTrue);
      expect(updated.includeRegional, isTrue);
      expect(updated.includeMega, isTrue);
      expect(updated.includeGMax, isTrue);
      expect(updated.includeOther, isTrue);
      expect(updated.isShinyDex, isTrue);

      verify(() => mockDb.saveUserDex(any())).called(greaterThanOrEqualTo(2));
    });

    test('updateSortSettings aktualisiert Sortier-Einstellungen und speichert in DB', () async {
      provider.createDex('Test Dex', 'kanto', false, false, false, false, false, false, 'root');
      final dex = provider.userDexes.first;

      await provider.updateSortSettings(
        dex: dex,
        megaSort: 'custom_mega',
        gmaxSort: 'custom_gmax',
        regionalSort: 'custom_reg',
      );

      expect(dex.megaSort, equals('custom_mega'));
      expect(dex.gmaxSort, equals('custom_gmax'));
      expect(dex.regionalSort, equals('custom_reg'));

      verify(() => mockDb.saveUserDex(dex)).called(greaterThanOrEqualTo(1));
    });

    test('updateStructureOrder setzt neue Reihenfolge in Struktur', () {
      provider.structure['root'] = ['a', 'b', 'c'];

      provider.updateStructureOrder('root', ['c', 'a', 'b']);

      expect(provider.structure['root'], equals(['c', 'a', 'b']));
      verify(() => mockDb.saveStructure(any())).called(greaterThan(0));
    });

    test('deleteFolder ohne Rekursion rettet Kinder in Root', () async {
      provider.folders.add(DexFolder(id: 'folder_test', title: 'Test Folder'));
      provider.structure['root'] = ['folder_test'];
      provider.structure['folder_test'] = ['child_1', 'child_2'];

      await provider.deleteFolder('folder_test', false);

      expect(provider.folders.any((f) => f.id == 'folder_test'), isFalse);
      expect(provider.structure.containsKey('folder_test'), isFalse);
      expect(provider.structure['root'], containsAll(['child_1', 'child_2']));
      expect(provider.structure['root'], isNot(contains('folder_test')));

      verify(() => mockDb.deleteFolder('folder_test', recursive: false)).called(1);
    });

    test('deleteFolder mit Rekursion löscht Kinder ohne Rettung in Root', () async {
      provider.folders.add(DexFolder(id: 'folder_test', title: 'Test Folder'));
      provider.structure['root'] = ['folder_test'];
      provider.structure['folder_test'] = ['child_1', 'child_2'];

      await provider.deleteFolder('folder_test', true);

      expect(provider.folders.any((f) => f.id == 'folder_test'), isFalse);
      expect(provider.structure.containsKey('folder_test'), isFalse);
      expect(provider.structure['root'], isNot(contains('child_1')));
      expect(provider.structure['root'], isNot(contains('child_2')));

      verify(() => mockDb.deleteFolder('folder_test', recursive: true)).called(1);
    });

    test('togglePokemon fängt und entfängt Basis-Pokemon auf normalem Dex', () {
      provider.createDex('Normal Dex', 'kanto', false, false, false, false, false, false, 'root');
      final dexId = provider.userDexes.first.id;

      // Uncaught -> Caught
      provider.togglePokemon(dexId, '25');
      expect(provider.userDexes.first.caughtIds, contains('25'));
      verify(() => mockDb.savePokemonStatus(dexId, '25', isCaught: true)).called(1);

      // Caught -> Uncaught
      provider.togglePokemon(dexId, '25');
      expect(provider.userDexes.first.caughtIds, isNot(contains('25')));
      verify(() => mockDb.savePokemonStatus(dexId, '25', isCaught: false)).called(2);
    });

    test('togglePokemon mit Instanz-ID aktualisiert auch Base-ID', () {
      provider.createDex('Custom Box Dex', 'custom_empty', false, false, false, false, false, false, 'root');
      final dex = provider.userDexes.first;
      dex.customBoxes = [
        CustomBoxState(title: 'Box 1', pokemonIds: ['25__1', '25__2']),
      ];

      // Fange Instanz 25__1 -> Base-ID 25 wird auch gefangen
      provider.togglePokemon(dex.id, '25__1');
      expect(dex.caughtIds, containsAll(['25__1', '25']));

      // Entfange 25__1 -> Base-ID 25 wird auch entfangen (da 25__2 nicht gefangen ist)
      provider.togglePokemon(dex.id, '25__1');
      expect(dex.caughtIds, isNot(contains('25__1')));
      expect(dex.caughtIds, isNot(contains('25')));
    });

    test('togglePokemon auf ShinyDex synchronisiert Shiny-Status', () {
      provider.createDex('Shiny Dex', 'kanto', false, false, false, false, false, true, 'root');
      final dexId = provider.userDexes.first.id;

      // Auf ShinyDex: Wenn gefangen -> auch shiny
      provider.togglePokemon(dexId, '1');
      expect(provider.userDexes.first.caughtIds, contains('1'));
      expect(provider.userDexes.first.shinyIds, contains('1'));

      // Wenn entfangen -> auch shiny entfangen
      provider.togglePokemon(dexId, '1');
      expect(provider.userDexes.first.caughtIds, isNot(contains('1')));
      expect(provider.userDexes.first.shinyIds, isNot(contains('1')));
    });

    test('toggleShiny setzt und entfernt Shiny-Status und synchronisiert auf ShinyDex', () {
      provider.createDex('Shiny Dex', 'kanto', false, false, false, false, false, true, 'root');
      final dexId = provider.userDexes.first.id;

      provider.toggleShiny(dexId, '4');
      expect(provider.userDexes.first.shinyIds, contains('4'));
      expect(provider.userDexes.first.caughtIds, contains('4'));

      provider.toggleShiny(dexId, '4');
      expect(provider.userDexes.first.shinyIds, isNot(contains('4')));
      expect(provider.userDexes.first.caughtIds, isNot(contains('4')));
    });

    test('ignorePokemon und restorePokemon verwalten Ignorier-Liste', () {
      provider.createDex('Normal Dex', 'kanto', false, false, false, false, false, false, 'root');
      final dexId = provider.userDexes.first.id;

      provider.ignorePokemon(dexId, '150');
      expect(provider.userDexes.first.ignoredIds, contains('150'));
      verify(() => mockDb.savePokemonStatus(dexId, '150', isIgnored: true)).called(1);

      provider.restorePokemon(dexId, '150');
      expect(provider.userDexes.first.ignoredIds, isNot(contains('150')));
      verify(() => mockDb.savePokemonStatus(dexId, '150', isIgnored: false)).called(1);
    });

    test('importJsonData importiert Dexe, Ordner und Struktur erfolgreich', () async {
      final backupData = {
        'folders': [
          {'id': 'f_imported', 'title': 'Importierter Ordner'},
        ],
        'dexes': [
          {
            'id': 'd_imported',
            'title': 'Importierter Dex',
            'region': 'kanto',
            'includeGenders': false,
            'includeRegional': false,
            'includeMega': false,
            'includeGMax': false,
            'includeOther': false,
            'isShinyDex': false,
            'caughtIds': ['1', '4'],
            'shinyIds': ['1'],
            'ignoredIds': ['150'],
          },
        ],
        'structure': {
          'root': ['f_imported'],
          'f_imported': ['d_imported'],
        },
      };

      mockFileSelector.mockFileToReturn = XFile.fromData(
        utf8.encode(jsonEncode(backupData)),
        name: 'backup.json',
        mimeType: 'application/json',
      );

      await provider.importJsonData();

      expect(provider.folders.length, equals(1));
      expect(provider.folders.first.title, equals('Importierter Ordner'));
      expect(provider.userDexes.length, equals(1));
      expect(provider.userDexes.first.title, equals('Importierter Dex'));
      expect(provider.userDexes.first.caughtIds, containsAll(['1', '4']));
      expect(provider.structure['root'], equals(['f_imported']));
      expect(provider.structure['f_imported'], equals(['d_imported']));

      verify(() => mockDb.clearUserData()).called(1);
      verify(() => mockDb.saveFolder(any())).called(1);
      verify(() => mockDb.saveUserDex(any())).called(1);
      verify(() => mockDb.saveStructure(any())).called(1);
    });

    test('importJsonData bricht ab wenn keine Datei ausgewaehlt wird', () async {
      mockFileSelector.mockFileToReturn = null;

      await provider.importJsonData();

      verifyNever(() => mockDb.clearUserData());
    });
  });
}
