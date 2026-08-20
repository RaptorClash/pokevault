import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_dex.dart';
import '../services/dex_storage_service.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';

class DexProvider extends ChangeNotifier {
  List<UserDex> _userDexes = [];
  String _currentLanguage = 'de';
  ThemeMode _themeMode = ThemeMode.system;

  List<UserDex> get userDexes => _userDexes;
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

      final dexJson = prefs.getString('saved_dexes');
      if (dexJson != null) {
        final List<dynamic> decoded = jsonDecode(dexJson);
        _userDexes = decoded
            .map((item) => UserDex.fromJson(item as Map<String, dynamic>))
            .toList();
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

      final jsonList = _userDexes.map((d) => d.toJson()).toList();
      await prefs.setString('saved_dexes', jsonEncode(jsonList));
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void toggleTheme() {
    try {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void setLanguage(String langCode) {
    try {
      _currentLanguage = langCode;
      Translator.currentLanguage = langCode;
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
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
  ) {
    try {
      final newDex = UserDex(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void togglePokemon(String dexId, String entryId) {
    try {
      final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
      if (dexIndex != -1) {
        final dex = _userDexes[dexIndex];
        if (dex.caughtIds.contains(entryId)) {
          dex.caughtIds.remove(entryId);
          dex.shinyIds.remove(entryId);
        } else {
          dex.caughtIds.add(entryId);
          if (dex.isShinyDex) {
            dex.shinyIds.add(entryId);
          }
        }
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void toggleShiny(String dexId, String entryId) {
    try {
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
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void ignorePokemon(String dexId, String entryId) {
    try {
      final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
      if (dexIndex != -1) {
        final dex = _userDexes[dexIndex];
        dex.ignoredIds.add(entryId);
        dex.caughtIds.remove(entryId);
        dex.shinyIds.remove(entryId);
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void restorePokemon(String dexId, String entryId) {
    try {
      final dexIndex = _userDexes.indexWhere((d) => d.id == dexId);
      if (dexIndex != -1) {
        final dex = _userDexes[dexIndex];
        dex.ignoredIds.remove(entryId);
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  Future<void> importJsonData() async {
    try {
      final imported = await DexStorageService.importDexes(this);
      if (imported != null) {
        _userDexes.addAll(imported);
        _saveToPrefs();
        notifyListeners();
        NotificationHelper.showSuccess(Translator.get('import_success'));
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_import')} $e");
    }
  }

  void deleteDex(String dexId) {
    try {
      _userDexes.removeWhere((d) => d.id == dexId);
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
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
    try {
      final dexIndex = _userDexes.indexWhere((d) => d.id == id);
      if (dexIndex != -1) {
        final oldDex = _userDexes[dexIndex];
        final updatedDex = UserDex(
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
        _userDexes[dexIndex] = updatedDex;
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void deleteMultipleDexes(Set<String> dexIds) {
    try {
      _userDexes.removeWhere((d) => dexIds.contains(d.id));
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_save')} $e");
    }
  }

  void reorderDexes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final dex = userDexes.removeAt(oldIndex);
    userDexes.insert(newIndex, dex);

    _saveToPrefs();

    notifyListeners();
  }
}
