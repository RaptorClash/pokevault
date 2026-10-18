import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../utils/dex_logic_helper.dart';
import '../services/database_service.dart';
import '../services/dex_storage_service.dart';
import '../services/migration_service.dart';
import '../utils/notification_helper.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_drive_sync_service.dart';
import '../models/ribbon.dart';
import '../models/shiny_hunt.dart';

class DexProvider extends ChangeNotifier with WidgetsBindingObserver {
  List<UserDex> userDexes = [];
  List<DexFolder> folders = [];
  Map<String, List<String>> structure = {'root': []};

  List<Pokemon> allPokemon = [];
  Map<String, List<int>> allAvailableDexes = {};
  Map<String, String> ballUrls = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool _isDisposed = false;
  Future<void>? _initFuture;
  Future<void> get initialized => _initFuture ?? Future.value();

  bool isMigrating = false;

  final DatabaseService db;

  Timer? _uploadDebouncer;
  Timer? _downloadTimer;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _hasPendingChanges = false;
  List<Ribbon> allRibbons = [];

  final List<Future<void> Function()> _beforeUploadHooks = [];
  final List<Future<void> Function()> _beforeMergeHooks = [];
  final List<Future<void> Function()> _cloudDataMergedHooks = [];

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

  @visibleForTesting
  Future<void> runBeforeUploadHooksForTesting() async {
    for (final hook in _beforeUploadHooks) {
      await hook();
    }
  }

  DexProvider({DatabaseService? databaseService})
    : db = databaseService ?? DatabaseService.instance {
    _initFuture = _init();
    WidgetsBinding.instance.addObserver(this);
    _downloadTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkForRemoteUpdates();
    });
  }

  void forceRefresh() { notifyListeners(); }

  Future<void> updateSortSettings({
    required UserDex dex,
    required String megaSort,
    required String gmaxSort,
    required String regionalSort,
  }) async {
    dex.megaSort = megaSort;
    dex.gmaxSort = gmaxSort;
    dex.regionalSort = regionalSort;
    await db.saveUserDex(dex);
    triggerAutoUpload();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
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
      allRibbons = await db.getAllRibbons();

      if (_isDisposed) return;
      _isInitialized = true;
      notifyListeners();
    } catch (e, stacktrace) {
      if (_isDisposed) return;
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
      customBoxes: region == 'custom_empty'
          ? [CustomBoxState(title: "Box 1", pokemonIds: [], regionKey: region, columns: 6, rows: 5)]
          : [],
    );
    userDexes.add(newDex);
    structure.putIfAbsent(folderId, () => []).add(newDex.id);

    db.saveUserDex(newDex);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  Future<void> saveUserDexAndSync(UserDex dex) async {
    final index = userDexes.indexWhere((d) => d.id == dex.id);
    if (index != -1) {
      userDexes[index] = dex;
    } else {
      userDexes.add(dex);
    }
    await db.saveUserDex(dex);
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

  Future<void> deleteFolder(String folderId, bool recursive) async {
    if (!recursive) {
      final childrenToRescue = structure[folderId] ?? [];
      structure['root']?.addAll(childrenToRescue);
    }

    structure.remove(folderId);
    for (var list in structure.values) {
      list.remove(folderId);
    }

    folders.removeWhere((f) => f.id == folderId);
    notifyListeners();

    await db.deleteFolder(folderId, recursive: recursive);
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
        newIndex > list.length) {
      return;
    }

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
      if (child.startsWith('folder_') && isDescendant(child, potentialChildId)) {
        return true;
      }
    }
    return false;
  }

  void togglePokemon(String dexId, String pokemonUniqueId) {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    final isCurrentlyCaught = DexLogicHelper.isPokemonCaught(dex, pokemonUniqueId);
    final isCaught = !isCurrentlyCaught;

    final isInstance = pokemonUniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(pokemonUniqueId);

    if (isCaught) {
      if (!dex.caughtIds.contains(pokemonUniqueId)) {
        dex.caughtIds.add(pokemonUniqueId);
      }
      db.savePokemonStatus(dexId, pokemonUniqueId, isCaught: true);

      if (isInstance) {
        final wasBaseIdCaught = dex.caughtIds.contains(baseId);
        final hadOtherInstanceCaught = dex.caughtIds.any((id) =>
            id != pokemonUniqueId && id.startsWith('${baseId}__'));

        if (baseId.isNotEmpty && !wasBaseIdCaught) {
          dex.caughtIds.add(baseId);
          db.savePokemonStatus(dexId, baseId, isCaught: true);
        }
        if (wasBaseIdCaught && !hadOtherInstanceCaught) {
          final allInst = dex.customBoxes
              .expand((b) => b.pokemonIds)
              .where((id) =>
                  !DexLogicHelper.isPlaceholder(id) &&
                  DexLogicHelper.getBaseId(id) == baseId)
              .toList();
          if (allInst.isNotEmpty && allInst.first != pokemonUniqueId) {
            final primaryInst = allInst.first;
            if (!dex.caughtIds.contains(primaryInst)) {
              dex.caughtIds.add(primaryInst);
              db.savePokemonStatus(dexId, primaryInst, isCaught: true);
            }
          }
        }
      } else {
        for (var box in dex.customBoxes) {
          for (var id in box.pokemonIds) {
            if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
              if (!dex.caughtIds.contains(id)) {
                dex.caughtIds.add(id);
              }
              db.savePokemonStatus(dexId, id, isCaught: true);
            }
          }
        }
      }
      triggerAutoUpload();
    } else {
      dex.caughtIds.remove(pokemonUniqueId);
      db.savePokemonStatus(dexId, pokemonUniqueId, isCaught: false);

      if (isInstance) {
        final hasOtherCaughtInstance = dex.customBoxes
            .expand((b) => b.pokemonIds)
            .any((id) =>
                id != pokemonUniqueId &&
                id.contains('__') &&
                DexLogicHelper.getBaseId(id) == baseId &&
                dex.caughtIds.contains(id));
        if (!hasOtherCaughtInstance) {
          dex.caughtIds.remove(baseId);
          db.savePokemonStatus(dexId, baseId, isCaught: false);
        }
      } else {
        dex.caughtIds.remove(baseId);
        db.savePokemonStatus(dexId, baseId, isCaught: false);
        for (var box in dex.customBoxes) {
          for (var id in box.pokemonIds) {
            if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
              dex.caughtIds.remove(id);
              db.savePokemonStatus(dexId, id, isCaught: false);
            }
          }
        }
      }
      triggerAutoUpload();
    }

    if (dex.isShinyDex) {
      final isCurrentlyShiny = DexLogicHelper.isPokemonShiny(dex, pokemonUniqueId);
      if (isCurrentlyShiny != isCaught) {
        if (isCaught) {
          if (!dex.shinyIds.contains(pokemonUniqueId)) {
            dex.shinyIds.add(pokemonUniqueId);
          }
          db.savePokemonStatus(dexId, pokemonUniqueId, isShiny: true);
          if (isInstance) {
            final wasBaseIdShiny = dex.shinyIds.contains(baseId);
            final hadOtherInstanceShiny = dex.shinyIds.any((id) =>
                id != pokemonUniqueId && id.startsWith('${baseId}__'));

            if (baseId.isNotEmpty && !wasBaseIdShiny) {
              dex.shinyIds.add(baseId);
              db.savePokemonStatus(dexId, baseId, isShiny: true);
            }
            if (wasBaseIdShiny && !hadOtherInstanceShiny) {
              final allInst = dex.customBoxes
                  .expand((b) => b.pokemonIds)
                  .where((id) =>
                      !DexLogicHelper.isPlaceholder(id) &&
                      DexLogicHelper.getBaseId(id) == baseId)
                  .toList();
              if (allInst.isNotEmpty && allInst.first != pokemonUniqueId) {
                final primaryInst = allInst.first;
                if (!dex.shinyIds.contains(primaryInst)) {
                  dex.shinyIds.add(primaryInst);
                  db.savePokemonStatus(dexId, primaryInst, isShiny: true);
                }
              }
            }
          } else {
            for (var box in dex.customBoxes) {
              for (var id in box.pokemonIds) {
                if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
                  if (!dex.shinyIds.contains(id)) dex.shinyIds.add(id);
                  db.savePokemonStatus(dexId, id, isShiny: true);
                }
              }
            }
          }
        } else {
          dex.shinyIds.remove(pokemonUniqueId);
          db.savePokemonStatus(dexId, pokemonUniqueId, isShiny: false);
          if (isInstance) {
            final hasOtherShinyInstance = dex.customBoxes
                .expand((b) => b.pokemonIds)
                .any((id) =>
                    id != pokemonUniqueId &&
                    id.contains('__') &&
                    DexLogicHelper.getBaseId(id) == baseId &&
                    dex.shinyIds.contains(id));
            if (!hasOtherShinyInstance) {
              dex.shinyIds.remove(baseId);
              db.savePokemonStatus(dexId, baseId, isShiny: false);
            }
          } else {
            dex.shinyIds.remove(baseId);
            db.savePokemonStatus(dexId, baseId, isShiny: false);
            for (var box in dex.customBoxes) {
              for (var id in box.pokemonIds) {
                if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
                  dex.shinyIds.remove(id);
                  db.savePokemonStatus(dexId, id, isShiny: false);
                }
              }
            }
          }
        }
        triggerAutoUpload();
      }
    }

    notifyListeners();
  }

  void toggleShiny(String dexId, String pokemonUniqueId) {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    final isCurrentlyShiny = DexLogicHelper.isPokemonShiny(dex, pokemonUniqueId);
    final isShiny = !isCurrentlyShiny;

    final isInstance = pokemonUniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(pokemonUniqueId);

    if (isShiny) {
      if (!dex.shinyIds.contains(pokemonUniqueId)) {
        dex.shinyIds.add(pokemonUniqueId);
      }
      db.savePokemonStatus(dexId, pokemonUniqueId, isShiny: true);

      if (isInstance) {
        final wasBaseIdShiny = dex.shinyIds.contains(baseId);
        final hadOtherInstanceShiny = dex.shinyIds.any((id) =>
            id != pokemonUniqueId && id.startsWith('${baseId}__'));

        if (baseId.isNotEmpty && !wasBaseIdShiny) {
          dex.shinyIds.add(baseId);
          db.savePokemonStatus(dexId, baseId, isShiny: true);
        }
        if (wasBaseIdShiny && !hadOtherInstanceShiny) {
          final allInst = dex.customBoxes
              .expand((b) => b.pokemonIds)
              .where((id) =>
                  !DexLogicHelper.isPlaceholder(id) &&
                  DexLogicHelper.getBaseId(id) == baseId)
              .toList();
          if (allInst.isNotEmpty && allInst.first != pokemonUniqueId) {
            final primaryInst = allInst.first;
            if (!dex.shinyIds.contains(primaryInst)) {
              dex.shinyIds.add(primaryInst);
              db.savePokemonStatus(dexId, primaryInst, isShiny: true);
            }
          }
        }
      } else {
        for (var box in dex.customBoxes) {
          for (var id in box.pokemonIds) {
            if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
              if (!dex.shinyIds.contains(id)) {
                dex.shinyIds.add(id);
              }
              db.savePokemonStatus(dexId, id, isShiny: true);
            }
          }
        }
      }
      triggerAutoUpload();
    } else {
      dex.shinyIds.remove(pokemonUniqueId);
      db.savePokemonStatus(dexId, pokemonUniqueId, isShiny: false);

      if (isInstance) {
        final hasOtherShinyInstance = dex.customBoxes
            .expand((b) => b.pokemonIds)
            .any((id) =>
                id != pokemonUniqueId &&
                id.contains('__') &&
                DexLogicHelper.getBaseId(id) == baseId &&
                dex.shinyIds.contains(id));
        if (!hasOtherShinyInstance) {
          dex.shinyIds.remove(baseId);
          db.savePokemonStatus(dexId, baseId, isShiny: false);
        }
      } else {
        dex.shinyIds.remove(baseId);
        db.savePokemonStatus(dexId, baseId, isShiny: false);
        for (var box in dex.customBoxes) {
          for (var id in box.pokemonIds) {
            if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
              dex.shinyIds.remove(id);
              db.savePokemonStatus(dexId, id, isShiny: false);
            }
          }
        }
      }
      triggerAutoUpload();
    }

    if (dex.isShinyDex) {
      final isCurrentlyCaught = DexLogicHelper.isPokemonCaught(dex, pokemonUniqueId);
      if (isCurrentlyCaught != isShiny) {
        if (isShiny) {
          if (!dex.caughtIds.contains(pokemonUniqueId)) {
            dex.caughtIds.add(pokemonUniqueId);
          }
          db.savePokemonStatus(dexId, pokemonUniqueId, isCaught: true);
          if (isInstance) {
            final wasBaseIdCaught = dex.caughtIds.contains(baseId);
            final hadOtherInstanceCaught = dex.caughtIds.any((id) =>
                id != pokemonUniqueId && id.startsWith('${baseId}__'));

            if (baseId.isNotEmpty && !wasBaseIdCaught) {
              dex.caughtIds.add(baseId);
              db.savePokemonStatus(dexId, baseId, isCaught: true);
            }
            if (wasBaseIdCaught && !hadOtherInstanceCaught) {
              final allInst = dex.customBoxes
                  .expand((b) => b.pokemonIds)
                  .where((id) =>
                      !DexLogicHelper.isPlaceholder(id) &&
                      DexLogicHelper.getBaseId(id) == baseId)
                  .toList();
              if (allInst.isNotEmpty && allInst.first != pokemonUniqueId) {
                final primaryInst = allInst.first;
                if (!dex.caughtIds.contains(primaryInst)) {
                  dex.caughtIds.add(primaryInst);
                  db.savePokemonStatus(dexId, primaryInst, isCaught: true);
                }
              }
            }
          } else {
            for (var box in dex.customBoxes) {
              for (var id in box.pokemonIds) {
                if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
                  if (!dex.caughtIds.contains(id)) dex.caughtIds.add(id);
                  db.savePokemonStatus(dexId, id, isCaught: true);
                }
              }
            }
          }
        } else {
          dex.caughtIds.remove(pokemonUniqueId);
          db.savePokemonStatus(dexId, pokemonUniqueId, isCaught: false);
          if (isInstance) {
            final hasOtherCaughtInstance = dex.customBoxes
                .expand((b) => b.pokemonIds)
                .any((id) =>
                    id != pokemonUniqueId &&
                    id.contains('__') &&
                    DexLogicHelper.getBaseId(id) == baseId &&
                    dex.caughtIds.contains(id));
            if (!hasOtherCaughtInstance) {
              dex.caughtIds.remove(baseId);
              db.savePokemonStatus(dexId, baseId, isCaught: false);
            }
          } else {
            dex.caughtIds.remove(baseId);
            db.savePokemonStatus(dexId, baseId, isCaught: false);
            for (var box in dex.customBoxes) {
              for (var id in box.pokemonIds) {
                if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
                  dex.caughtIds.remove(id);
                  db.savePokemonStatus(dexId, id, isCaught: false);
                }
              }
            }
          }
        }
        triggerAutoUpload();
      }
    }

    notifyListeners();
  }

  Future<void> markPokemonCaughtAndShiny(String dexId, String uniqueId) async {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];

    final isInstance = uniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(uniqueId);

    // 1. Mark as Caught
    if (!dex.caughtIds.contains(uniqueId)) {
      dex.caughtIds.add(uniqueId);
    }
    await db.savePokemonStatus(dexId, uniqueId, isCaught: true);

    if (isInstance) {
      if (baseId.isNotEmpty && !dex.caughtIds.contains(baseId)) {
        dex.caughtIds.add(baseId);
        await db.savePokemonStatus(dexId, baseId, isCaught: true);
      }
    } else {
      for (var box in dex.customBoxes) {
        for (var id in box.pokemonIds) {
          if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
            if (!dex.caughtIds.contains(id)) {
              dex.caughtIds.add(id);
            }
            await db.savePokemonStatus(dexId, id, isCaught: true);
          }
        }
      }
    }

    // 2. Mark as Shiny
    if (!dex.shinyIds.contains(uniqueId)) {
      dex.shinyIds.add(uniqueId);
    }
    await db.savePokemonStatus(dexId, uniqueId, isShiny: true);

    if (isInstance) {
      if (baseId.isNotEmpty && !dex.shinyIds.contains(baseId)) {
        dex.shinyIds.add(baseId);
        await db.savePokemonStatus(dexId, baseId, isShiny: true);
      }
    } else {
      for (var box in dex.customBoxes) {
        for (var id in box.pokemonIds) {
          if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
            if (!dex.shinyIds.contains(id)) {
              dex.shinyIds.add(id);
            }
            await db.savePokemonStatus(dexId, id, isShiny: true);
          }
        }
      }
    }

    triggerAutoUpload();
    notifyListeners();
  }

  void ignorePokemon(String dexId, String pokemonUniqueId) {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    if (!dex.ignoredIds.contains(pokemonUniqueId)) {
      dex.ignoredIds.add(pokemonUniqueId);
      db.savePokemonStatus(dexId, pokemonUniqueId, isIgnored: true);
      triggerAutoUpload();
      notifyListeners();
    }
  }

  void restorePokemon(String dexId, String pokemonUniqueId) {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    dex.ignoredIds.remove(pokemonUniqueId);
    db.savePokemonStatus(dexId, pokemonUniqueId, isIgnored: false);
    triggerAutoUpload();
    notifyListeners();
  }

  Future<void> importJsonData() async {
    final data = await DexStorageService.importDexes(this);
    if (data is Map<String, dynamic>) {
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

          for (var uid in d.caughtIds) {
            await db.savePokemonStatus(d.id, uid, isCaught: true);
          }
          for (var uid in d.shinyIds) {
            await db.savePokemonStatus(d.id, uid, isShiny: true);
          }
          for (var uid in d.ignoredIds) {
            await db.savePokemonStatus(d.id, uid, isIgnored: true);
          }
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

      if (data['shiny_hunts'] != null) {
        for (var hData in data['shiny_hunts']) {
          final h = ShinyHunt.fromMap(Map<String, dynamic>.from(hData));
          await db.saveShinyHunt(h);
        }
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
        for (var uid in rDex.caughtIds) {
          await db.savePokemonStatus(localDex.id, uid, isCaught: true);
        }
        for (var uid in rDex.shinyIds) {
          await db.savePokemonStatus(localDex.id, uid, isShiny: true);
        }
        for (var uid in rDex.ignoredIds) {
          await db.savePokemonStatus(localDex.id, uid, isIgnored: true);
        }
      } else {
        userDexes.add(rDex);
        await db.saveUserDex(rDex);
        for (var uid in rDex.caughtIds) {
          await db.savePokemonStatus(rDex.id, uid, isCaught: true);
        }
        for (var uid in rDex.shinyIds) {
          await db.savePokemonStatus(rDex.id, uid, isShiny: true);
        }
        for (var uid in rDex.ignoredIds) {
          await db.savePokemonStatus(rDex.id, uid, isIgnored: true);
        }
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
      for (final hook in _beforeUploadHooks) {
        try {
          await hook();
        } catch (e) {
          debugPrint('Error in beforeUploadHook: $e');
        }
      }
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

  Future<void> toggleRibbon(
    String dexId,
    String uniqueId,
    String ribbonId,
  ) async {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    final currentRibbons = List<String>.from(dex.caughtRibbons[uniqueId] ?? []);

    if (currentRibbons.contains(ribbonId)) {
      currentRibbons.remove(ribbonId);
    } else {
      currentRibbons.add(ribbonId);
    }

    dex.caughtRibbons[uniqueId] = currentRibbons;
    notifyListeners();
    await DatabaseService.instance.savePokemonStatus(
      dexId,
      uniqueId,
      ribbons: currentRibbons,
    );
  }

  Future<void> toggleTeraType(
    String dexId,
    String uniqueId,
    String teraType,
  ) async {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    final currentTeras = List<String>.from(dex.caughtTeraTypes[uniqueId] ?? []);

    if (currentTeras.contains(teraType)) {
      currentTeras.remove(teraType);
    } else {
      currentTeras.add(teraType);
    }

    dex.caughtTeraTypes[uniqueId] = currentTeras;
    notifyListeners();
    await DatabaseService.instance.savePokemonStatus(
      dexId,
      uniqueId,
      teraTypes: currentTeras,
    );
  }

  Future<void> toggleAlpha(String dexId, String uniqueId) async {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;

    final dex = userDexes[dexIndex];
    final isCurrentlyAlpha = DexLogicHelper.isPokemonAlpha(dex, uniqueId);
    final isAlpha = !isCurrentlyAlpha;
    final isInstance = uniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(uniqueId);

    if (isAlpha) {
      if (!dex.alphaIds.contains(uniqueId)) {
        dex.alphaIds.add(uniqueId);
      }
      await db.savePokemonStatus(
        dexId,
        uniqueId,
        isAlpha: true,
      );

      if (isInstance) {
        final wasBaseIdAlpha = dex.alphaIds.contains(baseId);
        final hadOtherInstanceAlpha = dex.alphaIds.any((id) =>
            id != uniqueId && id.startsWith('${baseId}__'));

        if (baseId.isNotEmpty && !wasBaseIdAlpha) {
          dex.alphaIds.add(baseId);
          await db.savePokemonStatus(dexId, baseId, isAlpha: true);
        }
        if (wasBaseIdAlpha && !hadOtherInstanceAlpha) {
          final allInst = dex.customBoxes
              .expand((b) => b.pokemonIds)
              .where((id) =>
                  !DexLogicHelper.isPlaceholder(id) &&
                  DexLogicHelper.getBaseId(id) == baseId)
              .toList();
          if (allInst.isNotEmpty && allInst.first != uniqueId) {
            final primaryInst = allInst.first;
            if (!dex.alphaIds.contains(primaryInst)) {
              dex.alphaIds.add(primaryInst);
              await db.savePokemonStatus(dexId, primaryInst, isAlpha: true);
            }
          }
        }
      } else {
        for (var box in dex.customBoxes) {
          for (var id in box.pokemonIds) {
            if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
              if (!dex.alphaIds.contains(id)) {
                dex.alphaIds.add(id);
              }
              await db.savePokemonStatus(dexId, id, isAlpha: true);
            }
          }
        }
      }
    } else {
      dex.alphaIds.remove(uniqueId);
      await db.savePokemonStatus(
        dexId,
        uniqueId,
        isAlpha: false,
      );

      if (isInstance) {
        final hasOtherAlphaInstance = dex.customBoxes
            .expand((b) => b.pokemonIds)
            .any((id) =>
                id != uniqueId &&
                id.contains('__') &&
                DexLogicHelper.getBaseId(id) == baseId &&
                dex.alphaIds.contains(id));
        if (!hasOtherAlphaInstance) {
          dex.alphaIds.remove(baseId);
          await db.savePokemonStatus(dexId, baseId, isAlpha: false);
        }
      } else {
        dex.alphaIds.remove(baseId);
        await db.savePokemonStatus(dexId, baseId, isAlpha: false);
        for (var box in dex.customBoxes) {
          for (var id in box.pokemonIds) {
            if (id.contains('__') && DexLogicHelper.getBaseId(id) == baseId) {
              dex.alphaIds.remove(id);
              await db.savePokemonStatus(dexId, id, isAlpha: false);
            }
          }
        }
      }
    }

    notifyListeners();
  }

  Future<void> updatePokemonLanguages(
    String dexId,
    String uniqueId,
    List<String> languages,
  ) async {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex != -1) {
      userDexes[dexIndex].caughtLanguages[uniqueId] = languages;
      notifyListeners();
      await DatabaseService.instance.savePokemonStatus(
        dexId,
        uniqueId,
        languages: languages,
      );
    }
  }
}
