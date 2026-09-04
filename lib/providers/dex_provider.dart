import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../services/database_service.dart';
import '../services/dex_storage_service.dart';
import '../services/migration_service.dart';
import '../utils/notification_helper.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_drive_sync_service.dart';

class DexProvider extends ChangeNotifier with WidgetsBindingObserver {
  List<UserDex> userDexes = [];
  List<DexFolder> folders = [];
  Map<String, List<String>> structure = {'root': []};

  List<Pokemon> allPokemon = [];
  Map<String, List<int>> allAvailableDexes = {};
  Map<String, String> ballUrls = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool isMigrating = false;

  final DatabaseService db;

  Timer? _uploadDebouncer;
  Timer? _downloadTimer;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _hasPendingChanges = false;

  DexProvider({DatabaseService? databaseService})
    : db = databaseService ?? DatabaseService.instance {
    _init();
    WidgetsBinding.instance.addObserver(this);
    _downloadTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkForRemoteUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uploadDebouncer?.cancel();
    _downloadTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_hasPendingChanges) {
        _executeSilentUpload();
      } else {
        _checkForRemoteUpdates();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_uploadDebouncer?.isActive ?? false) {
        _uploadDebouncer!.cancel();
        _executeSilentUpload();
      }
    }
  }

  void startAutoSyncIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    bool isAutoSync = prefs.getBool('autoSyncEnabled') ?? false;

    if (isAutoSync && GoogleDriveSyncService.instance.isSignedIn) {
      await _checkForRemoteUpdates();

      _downloadTimer?.cancel();
      _downloadTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _checkForRemoteUpdates();
      });
    }
  }

  Future<void> _checkForRemoteUpdates() async {
    if (!GoogleDriveSyncService.instance.isSignedIn || _isSyncing) return;

    final remoteTime = await GoogleDriveSyncService.instance
        .getRemoteModifiedTime();
    if (remoteTime == null) return;

    if (_lastSyncTime == null || remoteTime.isAfter(_lastSyncTime!)) {
      _isSyncing = true;
      try {
        debugPrint("Neue Daten in der Cloud gefunden! Lade herunter...");
        final cloudData = await GoogleDriveSyncService.instance
            .downloadBackup();
        if (cloudData != null) {
          await mergeCloudData(cloudData);
          _lastSyncTime = DateTime.now().toUtc();
        }
      } finally {
        _isSyncing = false;
      }
    }
  }

  void triggerAutoUpload() {
    if (!GoogleDriveSyncService.instance.isSignedIn) return;

    _uploadDebouncer?.cancel();
    _hasPendingChanges = true;

    _uploadDebouncer = Timer(const Duration(seconds: 3), () {
      _executeSilentUpload();
    });
  }

  Future<void> _init() async {
    try {
      isMigrating = true;
      notifyListeners();

      await MigrationService.migrateOldDataIfNeeded(db);

      isMigrating = false;

      allPokemon = await db.getAllPokemon();
      allAvailableDexes = await db.getAllDexOrders();
      ballUrls = await db.getBallUrls();

      userDexes = await db.getAllUserDexes();
      folders = await db.getAllFolders();
      structure = await db.getStructure();

      _isInitialized = true;
      notifyListeners();
    } catch (e, stacktrace) {
      NotificationHelper.showError("Fehler beim Laden der App-Daten: $e");
      debugPrint("Init Error: $e\n$stacktrace");
    }
  }

  void createDex(
    String title,
    String region,
    bool includeGenders,
    bool includeRegional,
    bool includeMega,
    bool includeGMax,
    bool includeOther,
    bool isShinyDex,
    String folderId,
  ) {
    final newDex = UserDex(
      id: const Uuid().v4(),
      title: title,
      region: region,
      includeGenders: includeGenders,
      includeRegional: includeRegional,
      includeMega: includeMega,
      includeGMax: includeGMax,
      includeOther: includeOther,
      isShinyDex: isShinyDex,
      caughtIds: [],
      shinyIds: [],
      ignoredIds: [],
    );
    userDexes.add(newDex);
    structure.putIfAbsent(folderId, () => []).add(newDex.id);

    db.saveUserDex(newDex);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  void updateDex(
    String id,
    String title,
    bool includeGenders,
    bool includeRegional,
    bool includeMega,
    bool includeGMax,
    bool includeOther,
    bool isShinyDex,
  ) {
    final index = userDexes.indexWhere((d) => d.id == id);
    if (index != -1) {
      final old = userDexes[index];
      final updated = UserDex(
        id: old.id,
        title: title,
        region: old.region,
        includeGenders: includeGenders,
        includeRegional: includeRegional,
        includeMega: includeMega,
        includeGMax: includeGMax,
        includeOther: includeOther,
        isShinyDex: isShinyDex,
        caughtIds: old.caughtIds,
        shinyIds: old.shinyIds,
        ignoredIds: old.ignoredIds,
      );
      userDexes[index] = updated;
      triggerAutoUpload();
      db.saveUserDex(updated);
      notifyListeners();
    }
  }

  void deleteDex(String id) {
    userDexes.removeWhere((d) => d.id == id);
    for (var key in structure.keys) {
      structure[key]?.remove(id);
    }
    db.deleteUserDex(id);
    triggerAutoUpload();
    db.saveStructure(structure);
    notifyListeners();
  }

  void createFolder(String title, String currentFolderId) {
    final folder = DexFolder(id: 'folder_${const Uuid().v4()}', title: title);
    folders.add(folder);
    structure.putIfAbsent(currentFolderId, () => []).add(folder.id);

    db.saveFolder(folder);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  void renameFolder(String id, String newTitle) {
    final idx = folders.indexWhere((f) => f.id == id);
    if (idx != -1) {
      folders[idx] = DexFolder(id: id, title: newTitle);
      db.saveFolder(folders[idx]);
      triggerAutoUpload();
      notifyListeners();
    }
  }

  void deleteFolder(String id) {
    folders.removeWhere((f) => f.id == id);
    for (var key in structure.keys) {
      structure[key]?.remove(id);
    }
    structure.remove(id);
    db.deleteFolder(id);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  void moveItem(String itemId, String newParentId) {
    for (var key in structure.keys) {
      structure[key]?.remove(itemId);
    }
    structure.putIfAbsent(newParentId, () => []).add(itemId);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  void updateStructureOrder(String parentId, List<String> newOrder) {
    structure[parentId] = newOrder;
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  void reorderItem(String folderId, int oldIndex, int newIndex) {
    if (!structure.containsKey(folderId)) return;

    final list = structure[folderId]!;
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex > list.length)
      return;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  bool isDescendant(String parentId, String potentialChildId) {
    if (parentId == potentialChildId) return true;
    final children = structure[parentId] ?? [];
    for (String child in children) {
      if (child.startsWith('folder_') && isDescendant(child, potentialChildId))
        return true;
    }
    return false;
  }

  void togglePokemon(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    bool isCaught = !dex.caughtIds.contains(pokemonUniqueId);

    if (isCaught) {
      dex.caughtIds.add(pokemonUniqueId);
      triggerAutoUpload();
    } else {
      dex.caughtIds.remove(pokemonUniqueId);
      triggerAutoUpload();
    }

    bool isCurrentlyShiny = dex.shinyIds.contains(pokemonUniqueId);

    if (dex.isShinyDex && isCurrentlyShiny != isCaught) {
      if (isCaught) {
        dex.shinyIds.add(pokemonUniqueId);
        triggerAutoUpload();
      } else {
        dex.shinyIds.remove(pokemonUniqueId);
        triggerAutoUpload();
      }
      db.savePokemonStatus(
        dexId,
        pokemonUniqueId,
        isCaught: isCaught,
        isShiny: isCaught,
      );
    } else {
      db.savePokemonStatus(dexId, pokemonUniqueId, isCaught: isCaught);
    }

    notifyListeners();
  }

  void toggleShiny(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    bool isShiny = !dex.shinyIds.contains(pokemonUniqueId);

    if (isShiny) {
      dex.shinyIds.add(pokemonUniqueId);
      triggerAutoUpload();
    } else {
      dex.shinyIds.remove(pokemonUniqueId);
      triggerAutoUpload();
    }

    bool isCurrentlyCaught = dex.caughtIds.contains(pokemonUniqueId);

    if (dex.isShinyDex && isCurrentlyCaught != isShiny) {
      if (isShiny) {
        dex.caughtIds.add(pokemonUniqueId);
        triggerAutoUpload();
      } else {
        dex.caughtIds.remove(pokemonUniqueId);
        triggerAutoUpload();
      }
      db.savePokemonStatus(
        dexId,
        pokemonUniqueId,
        isShiny: isShiny,
        isCaught: isShiny,
      );
    } else {
      db.savePokemonStatus(dexId, pokemonUniqueId, isShiny: isShiny);
      triggerAutoUpload();
    }

    notifyListeners();
  }

  void ignorePokemon(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    if (!dex.ignoredIds.contains(pokemonUniqueId)) {
      dex.ignoredIds.add(pokemonUniqueId);
      db.savePokemonStatus(dexId, pokemonUniqueId, isIgnored: true);
      triggerAutoUpload();
      notifyListeners();
    }
  }

  void restorePokemon(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    dex.ignoredIds.remove(pokemonUniqueId);
    db.savePokemonStatus(dexId, pokemonUniqueId, isIgnored: false);
    triggerAutoUpload();
    notifyListeners();
  }

  Future<void> importJsonData() async {
    final data = await DexStorageService.importDexes(this);
    if (data != null) {
      await db.clearUserData();

      folders.clear();
      userDexes.clear();
      structure.clear();

      if (data['folders'] != null) {
        for (var fData in data['folders']) {
          final f = DexFolder.fromJson(fData);
          folders.add(f);
          await db.saveFolder(f);
        }
      }

      if (data['dexes'] != null) {
        for (var dData in data['dexes']) {
          final d = UserDex.fromJson(dData);
          userDexes.add(d);
          await db.saveUserDex(d);

          for (var uid in d.caughtIds)
            await db.savePokemonStatus(d.id, uid, isCaught: true);
          for (var uid in d.shinyIds)
            await db.savePokemonStatus(d.id, uid, isShiny: true);
          for (var uid in d.ignoredIds)
            await db.savePokemonStatus(d.id, uid, isIgnored: true);
        }
      }

      if (data['structure'] != null) {
        final Map<String, dynamic> structData = data['structure'];
        structData.forEach((key, value) {
          structure[key] = List<String>.from(value);
        });
        await db.saveStructure(structure);
      } else {
        structure['root'] = userDexes.map((d) => d.id).toList();
        await db.saveStructure(structure);
      }

      notifyListeners();
      NotificationHelper.showSuccess('Import erfolgreich!');
      triggerAutoUpload();
    }
  }

  Future<void> reloadFromDatabase() async {
    userDexes = await db.getAllUserDexes();
    folders = await db.getAllFolders();
    structure = await db.getStructure();
    notifyListeners();
  }

  Future<void> mergeCloudData(Map<String, dynamic> cloudData) async {
    try {
      if (cloudData.containsKey('format_version') &&
          cloudData['format_version'] == 2) {
        await db.mergeCloudSyncData(cloudData);
      } else {
        if (userDexes.isEmpty && folders.isEmpty) {
          debugPrint("Lade altes Backup-Format herunter...");
          await _mergeOldFormat(cloudData);
        } else {
          debugPrint(
            "Veraltetes Cloud-Backup blockiert! (Verhindert Zombie-Dexe)",
          );
          _executeSilentUpload();
        }
      }

      await reloadFromDatabase();
    } catch (e) {
      debugPrint("Merge Error: $e");
      rethrow;
    }
  }

  Future<void> _mergeOldFormat(Map<String, dynamic> cloudData) async {
    final remoteDexes = (cloudData['dexes'] as List)
        .map((d) => UserDex.fromJson(d))
        .toList();
    for (var rDex in remoteDexes) {
      final localIndex = userDexes.indexWhere((d) => d.id == rDex.id);
      if (localIndex != -1) {
        final localDex = userDexes[localIndex];
        localDex.caughtIds = {
          ...localDex.caughtIds,
          ...rDex.caughtIds,
        }.toList();
        localDex.shinyIds = {...localDex.shinyIds, ...rDex.shinyIds}.toList();
        localDex.ignoredIds = {
          ...localDex.ignoredIds,
          ...rDex.ignoredIds,
        }.toList();
        await db.saveUserDex(localDex);
        for (var uid in rDex.caughtIds)
          await db.savePokemonStatus(localDex.id, uid, isCaught: true);
        for (var uid in rDex.shinyIds)
          await db.savePokemonStatus(localDex.id, uid, isShiny: true);
        for (var uid in rDex.ignoredIds)
          await db.savePokemonStatus(localDex.id, uid, isIgnored: true);
      } else {
        userDexes.add(rDex);
        await db.saveUserDex(rDex);
        for (var uid in rDex.caughtIds)
          await db.savePokemonStatus(rDex.id, uid, isCaught: true);
        for (var uid in rDex.shinyIds)
          await db.savePokemonStatus(rDex.id, uid, isShiny: true);
        for (var uid in rDex.ignoredIds)
          await db.savePokemonStatus(rDex.id, uid, isIgnored: true);
      }
    }
    final remoteFolders = (cloudData['folders'] as List)
        .map((f) => DexFolder.fromMap(f))
        .toList();
    for (var rFolder in remoteFolders) {
      if (!folders.any((f) => f.id == rFolder.id)) {
        folders.add(rFolder);
        await db.saveFolder(rFolder);
      }
    }
    final remoteStructure = Map<String, List<String>>.from(
      (cloudData['structure'] as Map).map(
        (k, v) => MapEntry(k.toString(), List<String>.from(v)),
      ),
    );
    structure.forEach((key, value) {
      if (!remoteStructure.containsKey(key)) {
        remoteStructure[key] = value;
      } else {
        final missing = value.where(
          (item) => !remoteStructure[key]!.contains(item),
        );
        remoteStructure[key]!.addAll(missing);
      }
    });
    structure = remoteStructure;
    await db.saveStructure(structure);
  }

  Future<void> _executeSilentUpload() async {
    if (!GoogleDriveSyncService.instance.isSignedIn || _isSyncing) return;

    _isSyncing = true;
    try {
      final Map<String, dynamic> exportData = await db.exportCloudSyncData();
      bool success = await GoogleDriveSyncService.instance.uploadBackup(
        exportData,
      );

      if (success) {
        debugPrint("Lautloser Upload erfolgreich.");
        _lastSyncTime = DateTime.now().toUtc();
        _hasPendingChanges = false;
      }
    } finally {
      _isSyncing = false;
    }
  }
}
