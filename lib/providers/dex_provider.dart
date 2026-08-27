import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_dex.dart';
import '../services/dex_storage_service.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';

class DexFolder {
  final String id;
  String title;

  DexFolder({required this.id, required this.title});

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
  factory DexFolder.fromJson(Map<String, dynamic> json) =>
      DexFolder(id: json['id'], title: json['title']);
}

class DexProvider extends ChangeNotifier {
  List<UserDex> _userDexes = [];
  List<DexFolder> _folders = [];
  Map<String, List<String>> _structure = {'root': []};

  String _currentLanguage = 'de';
  ThemeMode _themeMode = ThemeMode.system;

  List<UserDex> get userDexes => _userDexes;
  List<DexFolder> get folders => _folders;
  Map<String, List<String>> get structure => _structure;
  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;

  DexProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('language') ?? 'de';
      Translator.currentLanguage = _currentLanguage;

      final themeIndex = prefs.getInt('themeMode');
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      }

      final folderJson = prefs.getString('saved_folders');
      if (folderJson != null) {
        final List<dynamic> decodedF = jsonDecode(folderJson);
        _folders = decodedF.map((item) => DexFolder.fromJson(item)).toList();
      }

      final structureJson = prefs.getString('saved_structure');
      if (structureJson != null) {
        final Map<String, dynamic> decodedS = jsonDecode(structureJson);
        _structure = decodedS.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        );
      } else {
        _structure = {'root': []};
      }

      final dexJson = prefs.getString('saved_dexes');
      if (dexJson != null) {
        final List<dynamic> decoded = jsonDecode(dexJson);
        List<UserDex> loadedDexes = [];
        Set<String> seenIds = {};
        bool needsSave = false;

        for (var item in decoded) {
          UserDex dex = UserDex.fromJson(item as Map<String, dynamic>);

          if (seenIds.contains(dex.id)) {
            needsSave = true;
            dex = UserDex(
              id: 'dex_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
              title: dex.title,
              region: dex.region,
              caughtIds: Set.from(dex.caughtIds),
              ignoredIds: Set.from(dex.ignoredIds),
              shinyIds: Set.from(dex.shinyIds),
              includeGenders: dex.includeGenders,
              includeRegional: dex.includeRegional,
              includeMega: dex.includeMega,
              includeGMax: dex.includeGMax,
              includeOther: dex.includeOther,
              isShinyDex: dex.isShinyDex,
            );
          }
          seenIds.add(dex.id);
          loadedDexes.add(dex);

          bool inStructure = _structure.values.any(
            (list) => list.contains(dex.id),
          );
          if (!inStructure) {
            _structure['root']!.add(dex.id);
            needsSave = true;
          }
        }
        _userDexes = loadedDexes;
        if (needsSave) _saveToPrefs();
      }
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_load')} $e");
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _currentLanguage);
      await prefs.setInt('themeMode', _themeMode.index);
      await prefs.setString(
        'saved_dexes',
        jsonEncode(_userDexes.map((d) => d.toJson()).toList()),
      );
      await prefs.setString(
        'saved_folders',
        jsonEncode(_folders.map((f) => f.toJson()).toList()),
      );
      await prefs.setString('saved_structure', jsonEncode(_structure));
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  bool isDescendant(String folderId, String targetId) {
    if (folderId == targetId) return true;
    final children = _structure[folderId] ?? [];
    for (var child in children) {
      if (child == targetId) return true;
      if (child.startsWith('folder_') && isDescendant(child, targetId)) {
        return true;
      }
    }
    return false;
  }

  String? getParentFolder(String itemId) {
    for (var entry in _structure.entries) {
      if (entry.value.contains(itemId)) return entry.key;
    }
    return null;
  }

  void createFolder(String title, String currentFolderId) {
    final uniqueId =
        'folder_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    _folders.add(DexFolder(id: uniqueId, title: title));
    _structure[uniqueId] = [];
    _structure[currentFolderId]?.add(uniqueId);
    _saveToPrefs();
    notifyListeners();
  }

  bool moveItem(String itemId, String newParentId) {
    if (itemId.startsWith('folder_') && isDescendant(itemId, newParentId)) {
      NotificationHelper.showError(
        Translator.get('error_cyclic_move') != 'error_cyclic_move'
            ? Translator.get('error_cyclic_move')
            : 'Ein Ordner kann nicht in sich selbst verschoben werden!',
      );
      return false;
    }

    for (var key in _structure.keys) {
      if (_structure[key]!.contains(itemId)) {
        _structure[key]!.remove(itemId);
        break;
      }
    }
    _structure[newParentId]?.add(itemId);
    _saveToPrefs();
    notifyListeners();
    return true;
  }

  void deleteFolder(String folderId) {
    final contents = _structure[folderId] ?? [];
    _structure['root']!.addAll(contents);
    _structure.remove(folderId);
    _folders.removeWhere((f) => f.id == folderId);
    for (var key in _structure.keys) {
      _structure[key]!.remove(folderId);
    }
    _saveToPrefs();
    notifyListeners();
  }

  void renameFolder(String folderId, String newTitle) {
    final folder = _folders.firstWhere((f) => f.id == folderId);
    folder.title = newTitle;
    _saveToPrefs();
    notifyListeners();
  }

  void reorderItemsInFolder(String folderId, int oldIndex, int newIndex) {
    final list = _structure[folderId];
    if (list == null) return;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _structure[folderId] = List.from(list);

    _saveToPrefs();
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
    String currentFolderId,
  ) {
    final uniqueId =
        'dex_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
    final newDex = UserDex(
      id: uniqueId,
      title: title,
      region: region,
      caughtIds: {},
      ignoredIds: {},
      shinyIds: {},
      includeGenders: includeGenders,
      includeRegional: includeRegional,
      includeMega: includeMega,
      includeGMax: includeGMax,
      includeOther: includeOther,
      isShinyDex: isShinyDex,
    );
    _userDexes.add(newDex);
    _structure[currentFolderId]?.add(uniqueId);
    _saveToPrefs();
    notifyListeners();
  }

  void deleteDex(String dexId) {
    _userDexes.removeWhere((d) => d.id == dexId);
    for (var key in _structure.keys) {
      _structure[key]!.remove(dexId);
    }
    _saveToPrefs();
    notifyListeners();
  }

  void deleteMultipleDexes(Set<String> dexIds) {
    _userDexes.removeWhere((d) => dexIds.contains(d.id));
    for (var key in _structure.keys) {
      _structure[key]!.removeWhere((id) => dexIds.contains(id));
    }
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> importJsonData() async {
    try {
      final imported = await DexStorageService.importDexes(this);
      if (imported != null) {
        Set<String> existingIds = _userDexes.map((d) => d.id).toSet();
        Map<String, String> idMap = {};
        String getNewId(String oldId) => idMap[oldId] ?? oldId;

        if (imported is List) {
          for (var oldDex in imported) {
            UserDex dex = UserDex.fromJson(oldDex as Map<String, dynamic>);
            String newId = dex.id;
            if (existingIds.contains(newId)) {
              newId =
                  'dex_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
            }
            dex = UserDex(
              id: newId,
              title: dex.title,
              region: dex.region,
              caughtIds: dex.caughtIds,
              ignoredIds: dex.ignoredIds,
              shinyIds: dex.shinyIds,
              includeGenders: dex.includeGenders,
              includeRegional: dex.includeRegional,
              includeMega: dex.includeMega,
              includeGMax: dex.includeGMax,
              includeOther: dex.includeOther,
              isShinyDex: dex.isShinyDex,
            );
            existingIds.add(newId);
            _userDexes.add(dex);
            _structure['root']!.add(newId);
          }
        } else if (imported is Map) {
          if (imported['folders'] != null) {
            for (var fJson in imported['folders']) {
              DexFolder f = DexFolder.fromJson(fJson);
              if (_folders.any((existing) => existing.id == f.id)) {
                String newId =
                    'folder_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
                idMap[f.id] = newId;
                _folders.add(DexFolder(id: newId, title: f.title));
              } else {
                _folders.add(f);
              }
            }
          }

          if (imported['dexes'] != null) {
            for (var dJson in imported['dexes']) {
              UserDex d = UserDex.fromJson(dJson);
              if (existingIds.contains(d.id)) {
                String newId =
                    'dex_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
                idMap[d.id] = newId;
                _userDexes.add(
                  UserDex(
                    id: newId,
                    title: d.title,
                    region: d.region,
                    caughtIds: d.caughtIds,
                    ignoredIds: d.ignoredIds,
                    shinyIds: d.shinyIds,
                    includeGenders: d.includeGenders,
                    includeRegional: d.includeRegional,
                    includeMega: d.includeMega,
                    includeGMax: d.includeGMax,
                    includeOther: d.includeOther,
                    isShinyDex: d.isShinyDex,
                  ),
                );
              } else {
                _userDexes.add(d);
                existingIds.add(d.id);
              }
            }
          }

          if (imported['structure'] != null) {
            Map<String, dynamic> struct = imported['structure'];
            struct.forEach((oldParentId, children) {
              String parentId = oldParentId == 'root'
                  ? 'root'
                  : getNewId(oldParentId);
              _structure.putIfAbsent(parentId, () => []);
              for (var oldChildId in children) {
                String childId = getNewId(oldChildId);
                if (!_structure[parentId]!.contains(childId)) {
                  _structure[parentId]!.add(childId);
                }
              }
            });
          }
        }

        _saveToPrefs();
        notifyListeners();
        NotificationHelper.showSuccess(Translator.get('import_success'));
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_import')} $e");
    }
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
    final dexIndex = _userDexes.indexWhere((d) => d.id == id);
    if (dexIndex != -1) {
      final oldDex = _userDexes[dexIndex];
      _userDexes[dexIndex] = UserDex(
        id: oldDex.id,
        title: title,
        region: oldDex.region,
        caughtIds: oldDex.caughtIds,
        ignoredIds: oldDex.ignoredIds,
        shinyIds: oldDex.shinyIds,
        includeGenders: includeGenders,
        includeRegional: includeRegional,
        includeMega: includeMega,
        includeGMax: includeGMax,
        includeOther: includeOther,
        isShinyDex: isShinyDex,
      );
      _saveToPrefs();
      notifyListeners();
    }
  }

  void togglePokemon(String dexId, String entryId) {
    final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex != -1) {
      final dex = _userDexes[dexIndex];
      if (dex.caughtIds.contains(entryId)) {
        dex.caughtIds.remove(entryId);
        dex.shinyIds.remove(entryId);
      } else {
        dex.caughtIds.add(entryId);
        if (dex.isShinyDex) dex.shinyIds.add(entryId);
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  void toggleShiny(String dexId, String entryId) {
    final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex != -1) {
      final dex = _userDexes[dexIndex];
      if (dex.shinyIds.contains(entryId)) {
        dex.shinyIds.remove(entryId);
      } else {
        dex.shinyIds.add(entryId);
        dex.caughtIds.add(entryId);
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  void ignorePokemon(String dexId, String entryId) {
    final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex != -1) {
      final dex = _userDexes[dexIndex];
      dex.ignoredIds.add(entryId);
      dex.caughtIds.remove(entryId);
      dex.shinyIds.remove(entryId);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void restorePokemon(String dexId, String entryId) {
    final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
    if (dexIndex != -1) {
      final dex = _userDexes[dexIndex];
      dex.ignoredIds.remove(entryId);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _saveToPrefs();
    notifyListeners();
  }

  void setLanguage(String langCode) {
    _currentLanguage = langCode;
    Translator.currentLanguage = langCode;
    _saveToPrefs();
    notifyListeners();
  }

  void updateStructureOrder(String folderId, List<String> newOrder) {
    structure[folderId] = newOrder;
    notifyListeners();
    _saveToPrefs();
  }
}
