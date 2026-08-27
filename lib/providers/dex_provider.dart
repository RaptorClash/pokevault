import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/pokemon.dart';
import '../models/user_dex.dart';
import '../services/database_service.dart';
import '../services/dex_storage_service.dart';
import '../utils/notification_helper.dart';
import '../l10n/app_translations.dart';

class DexProvider with ChangeNotifier {
  List<UserDex> userDexes = [];
  List<DexFolder> folders = [];
  Map<String, List<String>> structure = {'root': []};

  List<Pokemon> allPokemon = [];
  Map<String, List<int>> allAvailableDexes = {};
  Map<String, String> ballUrls = {};

  ThemeMode themeMode = ThemeMode.system;
  String currentLanguage = 'de';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool isMigrating = false;

  DexProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      currentLanguage = prefs.getString('language') ?? 'de';
      Translator.currentLanguage = currentLanguage;

      String tm = 'system';
      try {
        tm = prefs.getString('themeMode') ?? 'system';
      } catch (_) {
        int oldTheme = prefs.getInt('themeMode') ?? 0;
        if (oldTheme == 1)
          tm = 'light';
        else if (oldTheme == 2)
          tm = 'dark';
        await prefs.setString('themeMode', tm);
      }

      if (tm == 'light')
        themeMode = ThemeMode.light;
      else if (tm == 'dark')
        themeMode = ThemeMode.dark;

      bool isMigrated = prefs.getBool('migrated_to_sqlite_v2') ?? false;
      if (!isMigrated) {
        if (prefs.getString('saved_dexes') != null ||
            prefs.getString('saved_folders') != null) {
          isMigrating = true;
          notifyListeners();

          await _migrateOldData(prefs);
        }

        await prefs.setBool('migrated_to_sqlite_v2', true);
        isMigrating = false;
      }
      allPokemon = await DatabaseService.instance.getAllPokemon();
      allAvailableDexes = await DatabaseService.instance.getAllDexOrders();
      ballUrls = await DatabaseService.instance.getBallUrls();

      userDexes = await DatabaseService.instance.getAllUserDexes();
      folders = await DatabaseService.instance.getAllFolders();
      structure = await DatabaseService.instance.getStructure();

      _isInitialized = true;
      notifyListeners();
    } catch (e, stacktrace) {
      NotificationHelper.showError("Fehler beim Laden der App-Daten: $e");
      debugPrint("Init Error: $e\n$stacktrace");
    }
  }

  Future<void> _migrateOldData(SharedPreferences prefs) async {
    try {
      debugPrint("Starte Daten-Migration in die SQLite-Datenbank...");

      String? oldDexesJson = prefs.getString('saved_dexes');
      String? oldFoldersJson = prefs.getString('saved_folders');
      String? oldStructureJson = prefs.getString('saved_structure');

      if (oldDexesJson != null) {
        List<dynamic> decodedDexes = jsonDecode(oldDexesJson);
        for (var d in decodedDexes) {
          UserDex dex = UserDex.fromJson(d as Map<String, dynamic>);
          await DatabaseService.instance.saveUserDex(dex);
          for (var uid in dex.caughtIds)
            await DatabaseService.instance.savePokemonStatus(
              dex.id,
              uid,
              isCaught: true,
            );
          for (var uid in dex.shinyIds)
            await DatabaseService.instance.savePokemonStatus(
              dex.id,
              uid,
              isShiny: true,
            );
          for (var uid in dex.ignoredIds)
            await DatabaseService.instance.savePokemonStatus(
              dex.id,
              uid,
              isIgnored: true,
            );
        }
      }

      if (oldFoldersJson != null) {
        List<dynamic> decodedFolders = jsonDecode(oldFoldersJson);
        for (var f in decodedFolders) {
          DexFolder folder = DexFolder.fromMap(f as Map<String, dynamic>);
          await DatabaseService.instance.saveFolder(folder);
        }
      }

      if (oldStructureJson != null) {
        Map<String, dynamic> decodedStruct = jsonDecode(oldStructureJson);
        Map<String, List<String>> newStruct = {};
        decodedStruct.forEach((key, value) {
          newStruct[key] = List<String>.from(value);
        });
        await DatabaseService.instance.saveStructure(newStruct);
      }

      await prefs.remove('saved_dexes');
      await prefs.remove('saved_folders');
      await prefs.remove('saved_structure');

      debugPrint("Migration erfolgreich abgeschlossen und Cache aufgeräumt!");
    } catch (e) {
      debugPrint("Fehler bei der automatischen Migration: $e");
    }
  }

  void setLanguage(String lang) async {
    currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    Translator.currentLanguage = lang;
    notifyListeners();
  }

  void toggleTheme() async {
    if (themeMode == ThemeMode.dark) {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.dark;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
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
    );
    userDexes.add(newDex);
    structure.putIfAbsent(folderId, () => []).add(newDex.id);

    DatabaseService.instance.saveUserDex(newDex);
    DatabaseService.instance.saveStructure(structure);
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
      DatabaseService.instance.saveUserDex(updated);
      notifyListeners();
    }
  }

  void deleteDex(String id) {
    userDexes.removeWhere((d) => d.id == id);
    for (var key in structure.keys) {
      structure[key]?.remove(id);
    }
    DatabaseService.instance.deleteUserDex(id);
    DatabaseService.instance.saveStructure(structure);
    notifyListeners();
  }

  void createFolder(String title, String currentFolderId) {
    final folder = DexFolder(id: 'folder_${const Uuid().v4()}', title: title);
    folders.add(folder);
    structure.putIfAbsent(currentFolderId, () => []).add(folder.id);

    DatabaseService.instance.saveFolder(folder);
    DatabaseService.instance.saveStructure(structure);
    notifyListeners();
  }

  void renameFolder(String id, String newTitle) {
    final idx = folders.indexWhere((f) => f.id == id);
    if (idx != -1) {
      folders[idx] = DexFolder(id: id, title: newTitle);
      DatabaseService.instance.saveFolder(folders[idx]);
      notifyListeners();
    }
  }

  void deleteFolder(String id) {
    folders.removeWhere((f) => f.id == id);
    for (var key in structure.keys) {
      structure[key]?.remove(id);
    }
    structure.remove(id);
    DatabaseService.instance.deleteFolder(id);
    DatabaseService.instance.saveStructure(structure);
    notifyListeners();
  }

  void moveItem(String itemId, String newParentId) {
    for (var key in structure.keys) {
      structure[key]?.remove(itemId);
    }
    structure.putIfAbsent(newParentId, () => []).add(itemId);
    DatabaseService.instance.saveStructure(structure);
    notifyListeners();
  }

  void updateStructureOrder(String parentId, List<String> newOrder) {
    structure[parentId] = newOrder;
    DatabaseService.instance.saveStructure(structure);
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
    } else {
      dex.caughtIds.remove(pokemonUniqueId);
    }
    DatabaseService.instance.savePokemonStatus(
      dexId,
      pokemonUniqueId,
      isCaught: isCaught,
    );
    notifyListeners();
  }

  void toggleShiny(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    bool isShiny = !dex.shinyIds.contains(pokemonUniqueId);
    if (isShiny) {
      dex.shinyIds.add(pokemonUniqueId);
    } else {
      dex.shinyIds.remove(pokemonUniqueId);
    }
    DatabaseService.instance.savePokemonStatus(
      dexId,
      pokemonUniqueId,
      isShiny: isShiny,
    );
    notifyListeners();
  }

  void ignorePokemon(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    if (!dex.ignoredIds.contains(pokemonUniqueId)) {
      dex.ignoredIds.add(pokemonUniqueId);
      DatabaseService.instance.savePokemonStatus(
        dexId,
        pokemonUniqueId,
        isIgnored: true,
      );
      notifyListeners();
    }
  }

  void restorePokemon(String dexId, String pokemonUniqueId) {
    final dex = userDexes.firstWhere((d) => d.id == dexId);
    dex.ignoredIds.remove(pokemonUniqueId);
    DatabaseService.instance.savePokemonStatus(
      dexId,
      pokemonUniqueId,
      isIgnored: false,
    );
    notifyListeners();
  }

  Future<void> importJsonData() async {
    final data = await DexStorageService.importDexes(this);
    if (data != null) {
      await DatabaseService.instance.clearUserData();

      folders.clear();
      userDexes.clear();
      structure.clear();

      if (data['folders'] != null) {
        for (var fData in data['folders']) {
          final f = DexFolder.fromJson(fData);
          folders.add(f);
          await DatabaseService.instance.saveFolder(f);
        }
      }

      if (data['dexes'] != null) {
        for (var dData in data['dexes']) {
          final d = UserDex.fromJson(dData);
          userDexes.add(d);
          await DatabaseService.instance.saveUserDex(d);

          for (var uid in d.caughtIds)
            await DatabaseService.instance.savePokemonStatus(
              d.id,
              uid,
              isCaught: true,
            );
          for (var uid in d.shinyIds)
            await DatabaseService.instance.savePokemonStatus(
              d.id,
              uid,
              isShiny: true,
            );
          for (var uid in d.ignoredIds)
            await DatabaseService.instance.savePokemonStatus(
              d.id,
              uid,
              isIgnored: true,
            );
        }
      }

      if (data['structure'] != null) {
        final Map<String, dynamic> structData = data['structure'];
        structData.forEach((key, value) {
          structure[key] = List<String>.from(value);
        });
        await DatabaseService.instance.saveStructure(structure);
      } else {
        structure['root'] = userDexes.map((d) => d.id).toList();
        await DatabaseService.instance.saveStructure(structure);
      }

      notifyListeners();
      NotificationHelper.showSuccess('Import erfolgreich!');
    }
  }
}
