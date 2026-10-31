import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/google_drive_sync_service.dart';
import 'package:pokevault/services/sync/google_drive_sync_coordinator.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockGoogleDriveSyncService extends Mock implements GoogleDriveSyncService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDatabaseService mockDb;
  late MockGoogleDriveSyncService mockSyncService;
  late GoogleDriveSyncCoordinator coordinator;
  late List<String> reloadCallLog;

  setUp(() {
    mockDb = MockDatabaseService();
    mockSyncService = MockGoogleDriveSyncService();
    reloadCallLog = [];

    when(() => mockSyncService.isSignedIn).thenReturn(true);
    when(() => mockSyncService.uploadBackup(any())).thenAnswer((_) async => true);
    when(() => mockSyncService.downloadBackup()).thenAnswer((_) async => {'format_version': 2});
    when(() => mockSyncService.getRemoteModifiedTime()).thenAnswer((_) async => null);
    when(() => mockDb.exportCloudSyncData()).thenAnswer((_) async => {'format_version': 2});
    when(() => mockDb.mergeCloudSyncData(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    coordinator.dispose();
  });

  group('GoogleDriveSyncCoordinator Isolated Tests (TDD)', () {
    test('Debouncer: triggerAutoUpload coalesces rapid requests into single upload', () async {
      coordinator = GoogleDriveSyncCoordinator(
        db: mockDb,
        onReloadRequired: () async {
          reloadCallLog.add('reloaded');
        },
        syncService: mockSyncService,
        startDownloadTimer: false,
        debouncerDuration: const Duration(milliseconds: 60),
      );

      expect(coordinator.hasPendingChanges, isFalse);

      coordinator.triggerAutoUpload();
      expect(coordinator.hasPendingChanges, isTrue);

      // Trigger multiple times rapidly
      coordinator.triggerAutoUpload();
      coordinator.triggerAutoUpload();

      // Immediately, uploadBackup should not have been called yet
      verifyNever(() => mockSyncService.uploadBackup(any()));

      // Wait past debouncer duration
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockSyncService.uploadBackup(any())).called(1);
      expect(coordinator.hasPendingChanges, isFalse);
    });

    test('Lifecycle Flush: AppLifecycleState.paused immediately flushes pending changes', () async {
      coordinator = GoogleDriveSyncCoordinator(
        db: mockDb,
        onReloadRequired: () async {},
        syncService: mockSyncService,
        startDownloadTimer: false,
        debouncerDuration: const Duration(seconds: 10), // long timer
      );

      coordinator.triggerAutoUpload();
      expect(coordinator.hasPendingChanges, isTrue);
      verifyNever(() => mockSyncService.uploadBackup(any()));

      // Pause triggers immediate flush
      coordinator.handleAppLifecycleState(AppLifecycleState.paused);

      // Allow flush microtask/async to execute
      await Future.delayed(const Duration(milliseconds: 20));

      verify(() => mockSyncService.uploadBackup(any())).called(1);
      expect(coordinator.hasPendingChanges, isFalse);
    });

    test('Hook sequence: executes beforeUpload, beforeMerge, and cloudDataMerged in exact order', () async {
      coordinator = GoogleDriveSyncCoordinator(
        db: mockDb,
        onReloadRequired: () async {
          reloadCallLog.add('reload');
        },
        syncService: mockSyncService,
        startDownloadTimer: false,
        debouncerDuration: const Duration(milliseconds: 10),
      );

      final List<String> hookLog = [];

      coordinator.registerBeforeUploadHook(() async {
        hookLog.add('beforeUpload');
      });
      coordinator.registerBeforeMergeHook(() async {
        hookLog.add('beforeMerge');
      });
      coordinator.registerCloudDataMergedHook(() async {
        hookLog.add('cloudDataMerged');
      });

      // 1. Test Upload Hook
      await coordinator.executeSilentUpload();
      expect(hookLog, equals(['beforeUpload']));

      // 2. Test Merge Hooks
      await coordinator.mergeCloudData(
        {'format_version': 2},
        isLocalEmpty: false,
        onMergeLegacyFormat: (_) async {},
      );

      expect(hookLog, equals(['beforeUpload', 'beforeMerge', 'cloudDataMerged']));
      expect(reloadCallLog, equals(['reload']));
    });

    test('checkForRemoteUpdates downloads and merges when remote timestamp is newer', () async {
      final now = DateTime.now().toUtc();
      when(() => mockSyncService.getRemoteModifiedTime()).thenAnswer((_) async => now);

      coordinator = GoogleDriveSyncCoordinator(
        db: mockDb,
        onReloadRequired: () async {
          reloadCallLog.add('reloaded');
        },
        syncService: mockSyncService,
        startDownloadTimer: false,
      );

      await coordinator.checkForRemoteUpdates();

      verify(() => mockSyncService.downloadBackup()).called(1);
      verify(() => mockDb.mergeCloudSyncData(any())).called(1);
      expect(reloadCallLog, contains('reloaded'));
      expect(coordinator.lastSyncTime, isNotNull);
    });
  });
}
