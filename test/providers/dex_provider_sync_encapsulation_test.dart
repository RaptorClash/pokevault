import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/sync/google_drive_sync_coordinator.dart';
import 'package:pokevault/models/user_dex.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockSyncCoordinator extends Mock implements GoogleDriveSyncCoordinator {}

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
    registerFallbackValue(AppLifecycleState.resumed);
  });

  group('DexProvider State Encapsulation and Sync Delegation Tests', () {
    late MockDatabaseService mockDb;
    late MockSyncCoordinator mockSyncCoordinator;
    late DexProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseService();
      mockSyncCoordinator = MockSyncCoordinator();

      when(() => mockDb.getAllPokemon()).thenAnswer((_) async => []);
      when(() => mockDb.getAllDexOrders()).thenAnswer((_) async => {});
      when(() => mockDb.getBallUrls()).thenAnswer((_) async => {});
      when(() => mockDb.getAllRibbons()).thenAnswer((_) async => []);
      when(() => mockDb.getAllUserDexes()).thenAnswer((_) async => []);
      when(() => mockDb.getAllFolders()).thenAnswer((_) async => []);
      when(() => mockDb.getStructure()).thenAnswer((_) async => {'root': []});
      when(() => mockDb.saveUserDex(any())).thenAnswer((_) async {});
      when(() => mockDb.saveStructure(any())).thenAnswer((_) async {});
      when(() => mockDb.saveFolder(any())).thenAnswer((_) async {});
      when(() => mockSyncCoordinator.triggerAutoUpload()).thenReturn(null);
      when(() => mockSyncCoordinator.dispose()).thenReturn(null);
      when(() => mockSyncCoordinator.handleAppLifecycleState(any())).thenReturn(null);
      when(() => mockSyncCoordinator.mergeCloudData(
        any(),
        isLocalEmpty: any(named: 'isLocalEmpty'),
        onMergeLegacyFormat: any(named: 'onMergeLegacyFormat'),
      )).thenAnswer((_) async {});

      provider = DexProvider(
        databaseService: mockDb,
        syncCoordinator: mockSyncCoordinator,
      );
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('userDexes and folders are unmodifiable from external access', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Test',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      final folder = DexFolder(id: 'folder_test', title: 'Test Folder');

      expect(() => provider.userDexes.add(dex), throwsA(isA<UnsupportedError>()));
      expect(() => provider.folders.add(folder), throwsA(isA<UnsupportedError>()));
    });

    test('addUserDexForTesting and addFolderForTesting mutate internal lists for testing', () {
      final dex = UserDex(
        id: 'test_dex',
        title: 'Test',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );
      final folder = DexFolder(id: 'folder_test', title: 'Test Folder');

      provider.addUserDexForTesting(dex);
      provider.addFolderForTesting(folder);

      expect(provider.userDexes.length, equals(1));
      expect(provider.userDexes.first.id, equals('test_dex'));
      expect(provider.folders.length, equals(1));
      expect(provider.folders.first.id, equals('folder_test'));
    });

    test('triggerAutoUpload delegates to syncCoordinator', () {
      provider.triggerAutoUpload();
      verify(() => mockSyncCoordinator.triggerAutoUpload()).called(1);
    });

    test('didChangeAppLifecycleState delegates to syncCoordinator', () {
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      verify(() => mockSyncCoordinator.handleAppLifecycleState(AppLifecycleState.paused)).called(1);
    });

    test('mergeCloudData delegates to syncCoordinator.mergeCloudData', () async {
      final testData = {'format_version': 2};
      await provider.mergeCloudData(testData);

      verify(() => mockSyncCoordinator.mergeCloudData(
        testData,
        isLocalEmpty: any(named: 'isLocalEmpty'),
        onMergeLegacyFormat: any(named: 'onMergeLegacyFormat'),
      )).called(1);
    });
  });
}
