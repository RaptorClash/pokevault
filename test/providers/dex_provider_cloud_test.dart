import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/user_dex.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

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

    registerFallbackValue(DexFolder(id: 'dummy', title: 'dummy'));
  });

  group('DexProvider Cloud Merge Tests', () {
    late DexProvider provider;
    late MockDatabaseService mockDb;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseService();

      when(() => mockDb.getAllPokemon()).thenAnswer((_) async => []);
      when(() => mockDb.getAllDexOrders()).thenAnswer((_) async => {});
      when(() => mockDb.getBallUrls()).thenAnswer((_) async => {});
      when(() => mockDb.getAllFolders()).thenAnswer((_) async => []);
      when(() => mockDb.getStructure()).thenAnswer((_) async => {'root': []});

      when(() => mockDb.saveUserDex(any())).thenAnswer((_) async {});
      when(() => mockDb.saveFolder(any())).thenAnswer((_) async {});
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

      when(() => mockDb.mergeCloudSyncData(any())).thenAnswer((_) async {});
      when(() => mockDb.exportCloudSyncData()).thenAnswer((_) async => {});

      final localDex = UserDex(
        id: 'dex_1',
        title: 'Mein Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      localDex.caughtIds = ['1_normal'];

      when(() => mockDb.getAllUserDexes()).thenAnswer((_) async => [localDex]);

      provider = DexProvider(databaseService: mockDb);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test(
      'Schutzschild: Blockiert altes V1-Backup, wenn lokale Daten existieren',
      () async {
        final Map<String, dynamic> mockOldCloudData = {
          'dexes': [
            {
              'id': 'dex_new',
              'title': 'Johto Dex',
              'region': 'johto',
              'includeGenders': false,
              'includeRegional': false,
              'includeMega': false,
              'includeGMax': false,
              'includeOther': false,
              'isShinyDex': false,
              'caughtIds': [],
              'shinyIds': [],
              'ignoredIds': [],
            },
          ],
          'folders': [],
          'structure': {
            'root': ['dex_new'],
          },
        };

        await provider.mergeCloudData(mockOldCloudData);

        expect(provider.userDexes.length, equals(1));
        expect(provider.userDexes.any((d) => d.id == 'dex_new'), isFalse);
        verifyNever(() => mockDb.saveUserDex(any()));
      },
    );

    test(
      'Fallback: Akzeptiert V1-Backup, wenn App komplett leer ist (Neuinstallation)',
      () async {
        List<UserDex> mockStorage = [];

        when(
          () => mockDb.getAllUserDexes(),
        ).thenAnswer((_) async => List.from(mockStorage));

        when(() => mockDb.saveUserDex(any())).thenAnswer((invocation) async {
          mockStorage.add(invocation.positionalArguments[0] as UserDex);
        });

        await provider.reloadFromDatabase();
        expect(provider.userDexes, isEmpty);

        final Map<String, dynamic> mockOldCloudData = {
          'dexes': [
            {
              'id': 'dex_old',
              'title': 'Mein Alter Dex',
              'region': 'kanto',
              'includeGenders': false,
              'includeRegional': false,
              'includeMega': false,
              'includeGMax': false,
              'includeOther': false,
              'isShinyDex': false,
              'caughtIds': ['1_normal'],
              'shinyIds': [],
              'ignoredIds': [],
            },
          ],
          'folders': [],
          'structure': {
            'root': ['dex_old'],
          },
        };

        await provider.mergeCloudData(mockOldCloudData);

        expect(provider.userDexes.length, equals(1));
        expect(provider.userDexes.first.id, equals('dex_old'));
        verify(() => mockDb.saveUserDex(any())).called(1);
      },
    );

    test(
      'CRDT: Leitet neues V2-Backup korrekt an DatabaseService weiter',
      () async {
        final Map<String, dynamic> mockV2CloudData = {
          'format_version': 2,
          'user_dexes': [],
          'folders': [],
          'folder_structure': [],
          'user_pokemon': [],
        };

        await provider.mergeCloudData(mockV2CloudData);

        verify(() => mockDb.mergeCloudSyncData(mockV2CloudData)).called(1);
        verify(() => mockDb.getAllUserDexes()).called(greaterThan(1));
      },
    );
  });
}
