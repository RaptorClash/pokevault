import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_dex.dart';
import 'database_service.dart';

class MigrationService {
  static Future<bool> migrateOldDataIfNeeded(DatabaseService db) async {
    final prefs = await SharedPreferences.getInstance();
    bool isMigrated = prefs.getBool('migrated_to_sqlite_v2') ?? false;

    if (isMigrated) return false;

    String? oldDexesJson = prefs.getString('saved_dexes');
    String? oldFoldersJson = prefs.getString('saved_folders');
    String? oldStructureJson = prefs.getString('saved_structure');

    if (oldDexesJson == null && oldFoldersJson == null) {
      await prefs.setBool('migrated_to_sqlite_v2', true);
      return false;
    }

    try {
      debugPrint("Starte Daten-Migration in die SQLite-Datenbank...");

      if (oldDexesJson != null) {
        List<dynamic> decodedDexes = jsonDecode(oldDexesJson);
        for (var d in decodedDexes) {
          UserDex dex = UserDex.fromJson(d as Map<String, dynamic>);
          await db.saveUserDex(dex);
          for (var uid in dex.caughtIds)
            await db.savePokemonStatus(dex.id, uid, isCaught: true);
          for (var uid in dex.shinyIds)
            await db.savePokemonStatus(dex.id, uid, isShiny: true);
          for (var uid in dex.ignoredIds)
            await db.savePokemonStatus(dex.id, uid, isIgnored: true);
        }
      }

      if (oldFoldersJson != null) {
        List<dynamic> decodedFolders = jsonDecode(oldFoldersJson);
        for (var f in decodedFolders) {
          DexFolder folder = DexFolder.fromMap(f as Map<String, dynamic>);
          await db.saveFolder(folder);
        }
      }

      if (oldStructureJson != null) {
        Map<String, dynamic> decodedStruct = jsonDecode(oldStructureJson);
        Map<String, List<String>> newStruct = {};
        decodedStruct.forEach((key, value) {
          newStruct[key] = List<String>.from(value);
        });
        await db.saveStructure(newStruct);
      }

      await prefs.remove('saved_dexes');
      await prefs.remove('saved_folders');
      await prefs.remove('saved_structure');
      await prefs.setBool('migrated_to_sqlite_v2', true);

      debugPrint("Migration erfolgreich abgeschlossen und Cache aufgeräumt!");
      return true;
    } catch (e) {
      debugPrint("Fehler bei der automatischen Migration: $e");
      return false;
    }
  }
}
