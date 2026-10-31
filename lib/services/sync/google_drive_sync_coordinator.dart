import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../google_drive_sync_service.dart';

/// Coordinates periodic background synchronization and debounced cloud backup
/// uploads to Google Drive with lifecycle management and pre/post sync hooks.
class GoogleDriveSyncCoordinator {
  final DatabaseService db;
  final GoogleDriveSyncService syncService;
  final Future<void> Function() onReloadRequired;
  final Duration debouncerDuration;
  final Duration checkInterval;

  Timer? _uploadDebouncer;
  Timer? _downloadTimer;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _hasPendingChanges = false;

  final List<Future<void> Function()> _beforeUploadHooks = [];
  final List<Future<void> Function()> _beforeMergeHooks = [];
  final List<Future<void> Function()> _cloudDataMergedHooks = [];

  bool get isSyncing => _isSyncing;
  bool get hasPendingChanges => _hasPendingChanges;
  DateTime? get lastSyncTime => _lastSyncTime;

  GoogleDriveSyncCoordinator({
    required this.db,
    required this.onReloadRequired,
    GoogleDriveSyncService? syncService,
    bool startDownloadTimer = true,
    this.debouncerDuration = const Duration(seconds: 3),
    this.checkInterval = const Duration(seconds: 60),
  }) : syncService = syncService ?? GoogleDriveSyncService.instance {
    if (startDownloadTimer) {
      _downloadTimer = Timer.periodic(checkInterval, (_) {
        checkForRemoteUpdates();
      });
    }
  }

  void registerBeforeUploadHook(Future<void> Function() hook) {
    if (!_beforeUploadHooks.contains(hook)) {
      _beforeUploadHooks.add(hook);
    }
  }

  void unregisterBeforeUploadHook(Future<void> Function() hook) {
    _beforeUploadHooks.remove(hook);
  }

  void registerBeforeMergeHook(Future<void> Function() hook) {
    if (!_beforeMergeHooks.contains(hook)) {
      _beforeMergeHooks.add(hook);
    }
  }

  void unregisterBeforeMergeHook(Future<void> Function() hook) {
    _beforeMergeHooks.remove(hook);
  }

  void registerCloudDataMergedHook(Future<void> Function() hook) {
    if (!_cloudDataMergedHooks.contains(hook)) {
      _cloudDataMergedHooks.add(hook);
    }
  }

  void unregisterCloudDataMergedHook(Future<void> Function() hook) {
    _cloudDataMergedHooks.remove(hook);
  }

  Future<void> runBeforeUploadHooks() async {
    for (final hook in _beforeUploadHooks) {
      await hook();
    }
  }

  void triggerAutoUpload() {
    if (!syncService.isSignedIn) return;

    _uploadDebouncer?.cancel();
    _hasPendingChanges = true;

    _uploadDebouncer = Timer(debouncerDuration, () {
      executeSilentUpload();
    });
  }

  Future<void> executeSilentUpload() async {
    if (!syncService.isSignedIn || _isSyncing) return;

    _isSyncing = true;
    try {
      for (final hook in _beforeUploadHooks) {
        try {
          await hook();
        } catch (e) {
          debugPrint('Error in beforeUploadHook: $e');
        }
      }
      final Map<String, dynamic> exportData = await db.exportCloudSyncData();
      bool success = await syncService.uploadBackup(exportData);

      if (success) {
        debugPrint("Lautloser Upload erfolgreich.");
        _lastSyncTime = DateTime.now().toUtc();
        _hasPendingChanges = false;
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> checkForRemoteUpdates() async {
    if (!syncService.isSignedIn || _isSyncing) return;

    final remoteTime = await syncService.getRemoteModifiedTime();
    if (remoteTime == null) return;

    if (_lastSyncTime == null || remoteTime.isAfter(_lastSyncTime!)) {
      _isSyncing = true;
      try {
        debugPrint("Neue Daten in der Cloud gefunden! Lade herunter...");
        final cloudData = await syncService.downloadBackup();
        if (cloudData != null) {
          await mergeCloudData(
            cloudData,
            isLocalEmpty: false,
            onMergeLegacyFormat: null,
          );
          _lastSyncTime = DateTime.now().toUtc();
        }
      } finally {
        _isSyncing = false;
      }
    }
  }

  Future<void> mergeCloudData(
    Map<String, dynamic> cloudData, {
    required bool isLocalEmpty,
    Future<void> Function(Map<String, dynamic>)? onMergeLegacyFormat,
  }) async {
    try {
      for (final hook in _beforeMergeHooks) {
        try {
          await hook();
        } catch (e) {
          debugPrint('Error in beforeMergeHook: $e');
        }
      }

      final formatVersion =
          (cloudData['format_version'] as num?)?.toInt() ?? 0;
      if (cloudData.containsKey('format_version') && formatVersion >= 2) {
        await db.mergeCloudSyncData(cloudData);
      } else {
        if (isLocalEmpty && onMergeLegacyFormat != null) {
          debugPrint("Lade altes Backup-Format herunter...");
          await onMergeLegacyFormat(cloudData);
        } else {
          debugPrint(
            "Veraltetes Cloud-Backup blockiert! (Verhindert Zombie-Dexe)",
          );
          await executeSilentUpload();
        }
      }

      await onReloadRequired();

      for (final hook in _cloudDataMergedHooks) {
        try {
          await hook();
        } catch (e) {
          debugPrint('Error in cloudDataMergedHook: $e');
        }
      }
    } catch (e) {
      debugPrint("Merge Error: $e");
      rethrow;
    }
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_hasPendingChanges) {
        executeSilentUpload();
      } else {
        checkForRemoteUpdates();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_uploadDebouncer?.isActive ?? false) {
        _uploadDebouncer!.cancel();
        executeSilentUpload();
      }
    }
  }

  void startAutoSyncIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    bool isAutoSync = prefs.getBool('autoSyncEnabled') ?? false;

    if (isAutoSync && syncService.isSignedIn) {
      await checkForRemoteUpdates();

      _downloadTimer?.cancel();
      _downloadTimer = Timer.periodic(checkInterval, (_) {
        checkForRemoteUpdates();
      });
    }
  }

  void dispose() {
    _uploadDebouncer?.cancel();
    _downloadTimer?.cancel();
  }
}
