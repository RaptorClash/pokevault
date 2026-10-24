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

/// Primary application state provider managing user Dexes, folders, and cloud synchronization.
///
/// Coordinates:
/// * Loading static Pokédex reference data from SQLite.
/// * Managing user-created Dexes, caught/shiny status mutations, and box configurations.
/// * Managing folder hierarchies and custom ordering.
/// * Periodic and debounced cloud synchronization with Google Drive.
/// * Lifecycle hooks for dependent providers (e.g. [ShinyHuntProvider]).
class DexProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// All user-created Pokédex configurations loaded from local storage.
  List<UserDex> userDexes = [];

  /// User-created folder containers for organizing Dexes.
  List<DexFolder> folders = [];

  /// Adjacency-list mapping representing the visual folder and Dex hierarchy.
  Map<String, List<String>> structure = {'root': []};

  /// Cached master list of all Pokémon entities from the reference database.
  List<Pokemon> allPokemon = [];

  /// Mapping of regional Dex keys to ordered lists of national Pokémon IDs.
  Map<String, List<int>> allAvailableDexes = {};

  /// Mapping of Pokéball identifiers to their image asset/network URLs.
  Map<String, String> ballUrls = {};

  bool _isInitialized = false;

  /// Whether the initial database and cache loading sequence has completed.
  bool get isInitialized => _isInitialized;
  bool _isDisposed = false;
  Future<void>? _initFuture;

  /// Future that completes when the provider is fully initialized.
  Future<void> get initialized => _initFuture ?? Future.value();

  /// Whether an active legacy data migration is currently in progress.
  bool isMigrating = false;

  /// Underlying SQLite database service instance.
  final DatabaseService db;

  Timer? _uploadDebouncer;
  Timer? _downloadTimer;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _hasPendingChanges = false;

  /// Master list of all available ribbons in the franchise.
  List<Ribbon> allRibbons = [];

  final List<Future<void> Function()> _beforeUploadHooks = [];
  final List<Future<void> Function()> _beforeMergeHooks = [];
  final List<Future<void> Function()> _cloudDataMergedHooks = [];

  /// Registers an asynchronous callback executed immediately before uploading local data to cloud.
  void registerBeforeUploadHook(Future<void> Function() hook) {
    if (!_beforeUploadHooks.contains(hook)) {
      _beforeUploadHooks.add(hook);
    }
  }

  /// Removes a previously registered upload hook callback.
  void unregisterBeforeUploadHook(Future<void> Function() hook) {
    _beforeUploadHooks.remove(hook);
  }

  /// Registers an asynchronous callback executed before merging downloaded cloud data.
  void registerBeforeMergeHook(Future<void> Function() hook) {
    if (!_beforeMergeHooks.contains(hook)) {
      _beforeMergeHooks.add(hook);
    }
  }

  /// Removes a previously registered merge hook callback.
  void unregisterBeforeMergeHook(Future<void> Function() hook) {
    _beforeMergeHooks.remove(hook);
  }

  /// Registers an asynchronous callback executed after cloud data has been merged.
  void registerCloudDataMergedHook(Future<void> Function() hook) {
    if (!_cloudDataMergedHooks.contains(hook)) {
      _cloudDataMergedHooks.add(hook);
    }
  }

  /// Removes a previously registered cloud data merged callback.
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

  /// Triggers a state refresh by notifying all active listeners.
  void forceRefresh() { notifyListeners(); }

  /// Updates sorting preferences (mega, gigantamax, and regional) for [dex] and persists them.
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
      sanitizeStructure();

      if (_isDisposed) return;
      _isInitialized = true;
      notifyListeners();
    } catch (e, stacktrace) {
      if (_isDisposed) return;
      NotificationHelper.showError("Fehler beim Laden der App-Daten: $e");
      debugPrint("Init Error: $e\n$stacktrace");
    }
  }

  /// Creates and persists a new [UserDex] configuration and adds it to [folderId].
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

  /// Saves the [dex] state to local SQLite and triggers an automated debounced cloud upload.
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

  /// Updates settings and metadata for the existing Dex with [id].
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

  /// Deletes the Dex with [id] from local memory, database, and folder structure.
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

  /// Creates a new visual folder container with [title] inside [currentFolderId].
  void createFolder(String title, String currentFolderId) {
    final folder = DexFolder(id: 'folder_${const Uuid().v4()}', title: title);
    folders.add(folder);
    structure.putIfAbsent(currentFolderId, () => []).add(folder.id);

    db.saveFolder(folder);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  /// Renames the folder identified by [id] to [newTitle].
  void renameFolder(String id, String newTitle) {
    final idx = folders.indexWhere((f) => f.id == id);
    if (idx != -1) {
      folders[idx] = DexFolder(id: id, title: newTitle);
      db.saveFolder(folders[idx]);
      triggerAutoUpload();
      notifyListeners();
    }
  }

  /// Deletes the folder with [folderId], optionally rescuing child elements to the root level.
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

  /// Moves an item (Dex or folder) identified by [itemId] into [newParentId].
  void moveItem(String itemId, String newParentId) {
    for (var key in structure.keys) {
      structure[key]?.remove(itemId);
    }
    structure.putIfAbsent(newParentId, () => []).add(itemId);
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  /// Updates the visual order of child items under [parentId] to match [newOrder].
  void updateStructureOrder(String parentId, List<String> newOrder) {
    structure[parentId] = newOrder;
    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  /// Reorders an item within [folderId] from [oldIndex] to [newIndex].
  void reorderItem(String folderId, int oldIndex, int newIndex) {
    if (!structure.containsKey(folderId)) return;

    final list = structure[folderId]!;
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex >= list.length) {
      return;
    }

    if (oldIndex == newIndex) return;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    db.saveStructure(structure);
    triggerAutoUpload();
    notifyListeners();
  }

  /// Returns whether [potentialChildId] is a nested descendant of [parentId].
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

  void _unmarkStatusForPokemon(
    String dexId,
    UserDex dex,
    String pokemonUniqueId, {
    required bool isCaughtStatus,
    required bool isShinyStatus,
    bool isAlphaStatus = false,
  }) {
    final isInstance = pokemonUniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(pokemonUniqueId);
    final rawBaseNumber = baseId.split('_').first;
    final isSecondary = DexLogicHelper.isSecondaryForm(baseId);

    bool matchesBase(String id) {
      final boxBase = DexLogicHelper.getBaseId(id);
      final rawBoxNumber = boxBase.split('_').first;
      if (boxBase == baseId) return true;
      if (rawBoxNumber == rawBaseNumber) {
        if (!DexLogicHelper.isSecondaryForm(baseId) && !DexLogicHelper.isSecondaryForm(boxBase)) {
          return true;
        }
      }
      return false;
    }

    void removeId(String id) {
      final bool hadShiny = isCaughtStatus && dex.shinyIds.contains(id);
      final bool hadAlpha = isCaughtStatus && dex.alphaIds.contains(id);

      if (isCaughtStatus) dex.caughtIds.remove(id);
      if (isShinyStatus || hadShiny) dex.shinyIds.remove(id);
      if (isAlphaStatus || hadAlpha) dex.alphaIds.remove(id);

      db.savePokemonStatus(
        dexId,
        id,
        isCaught: isCaughtStatus ? false : null,
        isShiny: (isShinyStatus || hadShiny) ? false : null,
        isAlpha: (isAlphaStatus || hadAlpha) ? false : null,
      );
    }

    final isMaleVariant = baseId == '${rawBaseNumber}_m' ||
        pokemonUniqueId == '${rawBaseNumber}_m' ||
        baseId == '${rawBaseNumber}_male' ||
        pokemonUniqueId == '${rawBaseNumber}_male';
    final isFemaleVariant = baseId == '${rawBaseNumber}_f' ||
        pokemonUniqueId == '${rawBaseNumber}_f' ||
        baseId == '${rawBaseNumber}_female' ||
        pokemonUniqueId == '${rawBaseNumber}_female';

    bool checkOtherGenderHasStatus() {
      if (isMaleVariant) {
        final femaleIds = ['${rawBaseNumber}_f', '${rawBaseNumber}_female'];
        return (isCaughtStatus && femaleIds.any(dex.caughtIds.contains)) ||
            (isShinyStatus && femaleIds.any(dex.shinyIds.contains)) ||
            (isAlphaStatus && femaleIds.any(dex.alphaIds.contains));
      } else if (isFemaleVariant) {
        final maleIds = ['${rawBaseNumber}_m', '${rawBaseNumber}_male', '${rawBaseNumber}_normal'];
        return (isCaughtStatus && maleIds.any(dex.caughtIds.contains)) ||
            (isShinyStatus && maleIds.any(dex.shinyIds.contains)) ||
            (isAlphaStatus && maleIds.any(dex.alphaIds.contains));
      }
      return false;
    }

    if (isInstance) {
      removeId(pokemonUniqueId);
      final hasOtherInstance = dex.customBoxes
          .expand((b) => b.pokemonIds)
          .any((id) =>
              id != pokemonUniqueId &&
              id.contains('__') &&
              matchesBase(id) &&
              ((isCaughtStatus && dex.caughtIds.contains(id)) ||
                  (isShinyStatus && dex.shinyIds.contains(id)) ||
                  (isAlphaStatus && dex.alphaIds.contains(id))));

      if (!hasOtherInstance) {
        removeId(baseId);
        if (isMaleVariant || isFemaleVariant) {
          if (!checkOtherGenderHasStatus()) {
            removeId(rawBaseNumber);
          }
        } else if (!isSecondary) {
          if (rawBaseNumber != baseId) {
            removeId(rawBaseNumber);
          }
          if ('${rawBaseNumber}_normal' != baseId) {
            removeId('${rawBaseNumber}_normal');
          }
          removeId('${rawBaseNumber}_m');
          removeId('${rawBaseNumber}_f');
        }
      }
    } else {
      removeId(pokemonUniqueId);
      removeId(baseId);

      if (isMaleVariant || isFemaleVariant) {
        if (!checkOtherGenderHasStatus()) {
          removeId(rawBaseNumber);
        }
      } else if (!isSecondary) {
        if (rawBaseNumber != pokemonUniqueId && rawBaseNumber != baseId) {
          removeId(rawBaseNumber);
        }
        if ('${rawBaseNumber}_normal' != pokemonUniqueId && '${rawBaseNumber}_normal' != baseId) {
          removeId('${rawBaseNumber}_normal');
        }
        removeId('${rawBaseNumber}_m');
        removeId('${rawBaseNumber}_f');
      }

      for (var box in dex.customBoxes) {
        for (var id in box.pokemonIds) {
          if (id.contains('__') && matchesBase(id)) {
            removeId(id);
          }
        }
      }
    }
  }

  /// Toggles the caught status of [pokemonUniqueId] within the Dex identified by [dexId].
  /// Optionally sets an explicit [targetState].
  void togglePokemon(String dexId, String pokemonUniqueId, {bool? targetState}) {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    final isCurrentlyCaught = DexLogicHelper.isPokemonCaught(dex, pokemonUniqueId);
    final isCaught = targetState ?? !isCurrentlyCaught;

    final isInstance = pokemonUniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(pokemonUniqueId);
    final rawBaseNumber = baseId.split('_').first;
    final isSecondary = DexLogicHelper.isSecondaryForm(baseId);

    if (isCaught) {
      if (!dex.caughtIds.contains(pokemonUniqueId)) {
        dex.caughtIds.add(pokemonUniqueId);
      }
      db.savePokemonStatus(dexId, pokemonUniqueId, isCaught: true);

      if (!isSecondary && !dex.caughtIds.contains(rawBaseNumber)) {
        dex.caughtIds.add(rawBaseNumber);
        db.savePokemonStatus(dexId, rawBaseNumber, isCaught: true);
      }

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
        if (baseId != pokemonUniqueId) {
          if (!dex.caughtIds.contains(baseId)) {
            dex.caughtIds.add(baseId);
          }
          db.savePokemonStatus(dexId, baseId, isCaught: true);
        }
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
      _unmarkStatusForPokemon(dexId, dex, pokemonUniqueId, isCaughtStatus: true, isShinyStatus: false);
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
          if (!isSecondary && !dex.shinyIds.contains(rawBaseNumber)) {
            dex.shinyIds.add(rawBaseNumber);
            db.savePokemonStatus(dexId, rawBaseNumber, isShiny: true);
          }
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
            if (baseId != pokemonUniqueId) {
              if (!dex.shinyIds.contains(baseId)) {
                dex.shinyIds.add(baseId);
              }
              db.savePokemonStatus(dexId, baseId, isShiny: true);
            }
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
          _unmarkStatusForPokemon(dexId, dex, pokemonUniqueId, isCaughtStatus: false, isShinyStatus: true);
        }
        triggerAutoUpload();
      }
    }

    notifyListeners();
  }

  void toggleShiny(String dexId, String pokemonUniqueId, {bool? targetState}) {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;
    final dex = userDexes[dexIndex];
    final isCurrentlyShiny = DexLogicHelper.isPokemonShiny(dex, pokemonUniqueId);
    final isShiny = targetState ?? !isCurrentlyShiny;

    final isInstance = pokemonUniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(pokemonUniqueId);
    final rawBaseNumber = baseId.split('_').first;
    final isSecondary = DexLogicHelper.isSecondaryForm(baseId);

    if (isShiny) {
      if (!dex.shinyIds.contains(pokemonUniqueId)) {
        dex.shinyIds.add(pokemonUniqueId);
      }
      db.savePokemonStatus(dexId, pokemonUniqueId, isShiny: true);

      if (!isSecondary && !dex.shinyIds.contains(rawBaseNumber)) {
        dex.shinyIds.add(rawBaseNumber);
        db.savePokemonStatus(dexId, rawBaseNumber, isShiny: true);
      }

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
        if (baseId != pokemonUniqueId) {
          if (!dex.shinyIds.contains(baseId)) {
            dex.shinyIds.add(baseId);
          }
          db.savePokemonStatus(dexId, baseId, isShiny: true);
        }
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
      _unmarkStatusForPokemon(dexId, dex, pokemonUniqueId, isCaughtStatus: false, isShinyStatus: true);
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
          if (!isSecondary && !dex.caughtIds.contains(rawBaseNumber)) {
            dex.caughtIds.add(rawBaseNumber);
            db.savePokemonStatus(dexId, rawBaseNumber, isCaught: true);
          }
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
            if (baseId != pokemonUniqueId) {
              if (!dex.caughtIds.contains(baseId)) {
                dex.caughtIds.add(baseId);
              }
              db.savePokemonStatus(dexId, baseId, isCaught: true);
            }
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
          _unmarkStatusForPokemon(dexId, dex, pokemonUniqueId, isCaughtStatus: true, isShinyStatus: false);
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

    String normalizedId = uniqueId;
    if (!normalizedId.contains('_')) {
      final poke = allPokemon.where((p) => p.id == int.tryParse(normalizedId)).firstOrNull;
      final formName = poke?.forms.firstOrNull?.name ?? 'normal';
      normalizedId = '${normalizedId}_$formName';
    }

    final isInstance = normalizedId.contains('__');
    final baseId = DexLogicHelper.getBaseId(normalizedId);
    final rawBaseNumber = baseId.split('_').first;

    bool matchesBase(String id) {
      final boxBase = DexLogicHelper.getBaseId(id);
      final rawBoxNumber = boxBase.split('_').first;
      if (boxBase == baseId) return true;
      if (rawBoxNumber == rawBaseNumber) {
        if (!DexLogicHelper.isSecondaryForm(baseId) && !DexLogicHelper.isSecondaryForm(boxBase)) {
          return true;
        }
      }
      return false;
    }

    // 1. Mark as Caught
    if (!dex.caughtIds.contains(normalizedId)) {
      dex.caughtIds.add(normalizedId);
    }
    await db.savePokemonStatus(dexId, normalizedId, isCaught: true);

    if (!DexLogicHelper.isSecondaryForm(baseId) && !dex.caughtIds.contains(rawBaseNumber)) {
      dex.caughtIds.add(rawBaseNumber);
      await db.savePokemonStatus(dexId, rawBaseNumber, isCaught: true);
    }

    if (uniqueId != normalizedId) {
      if (!dex.caughtIds.contains(uniqueId)) {
        dex.caughtIds.add(uniqueId);
      }
      await db.savePokemonStatus(dexId, uniqueId, isCaught: true);
    }

    if (isInstance) {
      if (baseId.isNotEmpty && !dex.caughtIds.contains(baseId)) {
        dex.caughtIds.add(baseId);
        await db.savePokemonStatus(dexId, baseId, isCaught: true);
      }
    } else {
      String? firstUncaught;
      for (var box in dex.customBoxes) {
        for (var id in box.pokemonIds) {
          if (id.contains('__') && matchesBase(id) && !dex.caughtIds.contains(id)) {
            firstUncaught = id;
            break;
          }
        }
        if (firstUncaught != null) break;
      }
      if (firstUncaught != null) {
        dex.caughtIds.add(firstUncaught);
        await db.savePokemonStatus(dexId, firstUncaught, isCaught: true);
      }
    }

    // Gender dex support
    final poke = allPokemon.where((p) => p.id == int.tryParse(rawBaseNumber)).firstOrNull;
    final bool hasGenderDiff = poke == null ? true : poke.hasGenderDifferences;
    if (dex.includeGenders && hasGenderDiff && !DexLogicHelper.isSecondaryForm(baseId)) {
      final maleId = '${rawBaseNumber}_m';
      final femaleId = '${rawBaseNumber}_f';
      final genderTarget = (!dex.caughtIds.contains(maleId)) ? maleId : femaleId;
      if (!dex.caughtIds.contains(genderTarget)) {
        dex.caughtIds.add(genderTarget);
        await db.savePokemonStatus(dexId, genderTarget, isCaught: true);
      }
      if (!dex.shinyIds.contains(genderTarget)) {
        dex.shinyIds.add(genderTarget);
        await db.savePokemonStatus(dexId, genderTarget, isShiny: true);
      }
    }

    // 2. Mark as Shiny
    if (!dex.shinyIds.contains(normalizedId)) {
      dex.shinyIds.add(normalizedId);
    }
    await db.savePokemonStatus(dexId, normalizedId, isShiny: true);

    if (!DexLogicHelper.isSecondaryForm(baseId) && !dex.shinyIds.contains(rawBaseNumber)) {
      dex.shinyIds.add(rawBaseNumber);
      await db.savePokemonStatus(dexId, rawBaseNumber, isShiny: true);
    }

    if (uniqueId != normalizedId) {
      if (!dex.shinyIds.contains(uniqueId)) {
        dex.shinyIds.add(uniqueId);
      }
      await db.savePokemonStatus(dexId, uniqueId, isShiny: true);
    }

    if (isInstance) {
      if (baseId.isNotEmpty && !dex.shinyIds.contains(baseId)) {
        dex.shinyIds.add(baseId);
        await db.savePokemonStatus(dexId, baseId, isShiny: true);
      }
    } else {
      String? firstUnshiny;
      for (var box in dex.customBoxes) {
        for (var id in box.pokemonIds) {
          if (id.contains('__') && matchesBase(id) && !dex.shinyIds.contains(id)) {
            firstUnshiny = id;
            break;
          }
        }
        if (firstUnshiny != null) break;
      }
      if (firstUnshiny != null) {
        dex.shinyIds.add(firstUnshiny);
        await db.savePokemonStatus(dexId, firstUnshiny, isShiny: true);
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
    sanitizeStructure();
    notifyListeners();
  }

  /// Sanitizes [structure] to remove orphaned IDs and ensure all folders/dexes are placed.
  void sanitizeStructure() {
    if (userDexes.isEmpty && folders.isEmpty) return;

    final validFolderIds = folders.map((f) => f.id).toSet();
    final validDexIds = userDexes.map((d) => d.id).toSet();
    bool changed = false;

    for (var key in structure.keys.toList()) {
      if (key != 'root' && !validFolderIds.contains(key)) {
        structure.remove(key);
        changed = true;
        continue;
      }
      final list = structure[key]!;
      final originalLen = list.length;
      list.retainWhere((id) =>
          id.startsWith('folder_') ? validFolderIds.contains(id) : validDexIds.contains(id));
      if (list.length != originalLen) {
        changed = true;
      }
    }

    structure.putIfAbsent('root', () => []);
    final allReferencedIds = structure.values.expand((l) => l).toSet();
    for (var folder in folders) {
      if (!allReferencedIds.contains(folder.id)) {
        structure['root']!.add(folder.id);
        changed = true;
      }
    }
    for (var dex in userDexes) {
      if (!allReferencedIds.contains(dex.id)) {
        structure['root']!.add(dex.id);
        changed = true;
      }
    }

    if (changed) {
      db.saveStructure(structure);
    }
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

  Future<void> toggleAlpha(String dexId, String uniqueId, {bool? targetState}) async {
    final dexIndex = userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex == -1) return;

    final dex = userDexes[dexIndex];
    final isCurrentlyAlpha = DexLogicHelper.isPokemonAlpha(dex, uniqueId);
    final isAlpha = targetState ?? !isCurrentlyAlpha;
    final isInstance = uniqueId.contains('__');
    final baseId = DexLogicHelper.getBaseId(uniqueId);
    final rawBaseNumber = baseId.split('_').first;
    final isSecondary = DexLogicHelper.isSecondaryForm(baseId);

    if (isAlpha) {
      if (!dex.alphaIds.contains(uniqueId)) {
        dex.alphaIds.add(uniqueId);
      }
      await db.savePokemonStatus(
        dexId,
        uniqueId,
        isAlpha: true,
      );

      if (!isSecondary && !dex.alphaIds.contains(rawBaseNumber)) {
        dex.alphaIds.add(rawBaseNumber);
        await db.savePokemonStatus(dexId, rawBaseNumber, isAlpha: true);
      }

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
        if (!dex.alphaIds.contains(baseId)) {
          dex.alphaIds.add(baseId);
        }
        await db.savePokemonStatus(dexId, baseId, isAlpha: true);
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
      _unmarkStatusForPokemon(dexId, dex, uniqueId, isCaughtStatus: false, isShinyStatus: false, isAlphaStatus: true);
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
