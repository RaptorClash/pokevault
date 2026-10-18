import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/user_dex.dart';
import '../models/shiny_hunt.dart';
import '../utils/notification_helper.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';

// Top-Level-Funktion für Isolate-Ausführung
String _encodeJsonTask(Map<String, dynamic> data) {
  return jsonEncode(data);
}

/// Service providing file export and import functionality for local JSON backups.
///
/// Offloads JSON encoding to a background isolate via [compute] to prevent UI jank.
/// Adapts file storage strategy to the target platform (Direct file writing on Desktop,
/// native Android public download storage with fallback sharing, and SharePlus on iOS/Web).
class DexStorageService {
  /// Exports all Dexes, folders, structure, and shiny hunts to a JSON backup file.
  ///
  /// Serializes the [dexes] list and additional data retrieved from [provider] in a
  /// background isolate, then delivers or shares the resulting file based on platform.
  static Future<void> exportDexes(
    List<UserDex> dexes,
    DexProvider provider,
  ) async {
    try {
      List<ShinyHunt> shinyHunts = [];
      try {
        shinyHunts = await provider.db.getAllShinyHunts();
      } catch (_) {
        shinyHunts = [];
      }
      final Map<String, dynamic> exportData = {
        'dexes': dexes.map((d) => d.toJson()).toList(),
        'folders': provider.folders.map((f) => f.toJson()).toList(),
        'structure': provider.structure,
        'shiny_hunts': shinyHunts.map((h) => h.toMap()).toList(),
      };

      // Schwere Arbeit in einen Hintergrund-Isolate auslagern
      final String jsonString = await compute(_encodeJsonTask, exportData);

      final String dateString = DateTime.now().toIso8601String().split('T')[0];
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'pokevault_backup_${dateString}_$timestamp.json';

      if (kIsWeb) {
        final bytes = utf8.encode(jsonString);
        final xFile = XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType: 'application/json',
        );

        await SharePlus.instance.share(ShareParams(files: [xFile], text: Translator.get('share_text')));

        NotificationHelper.showSuccess(
          Translator.get('backup_success', fallback: 'Backup heruntergeladen!'),
        );
        return;
      }

      bool isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;

      if (isDesktop) {
        Directory? directory = await getDownloadsDirectory();
        directory ??= await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);

        NotificationHelper.showSuccess(
          "${Translator.get('backup_success')}\n${file.path}",
        );
      } else if (Platform.isAndroid) {
        try {
          final directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            try {
              await directory.create();
            } catch (e) {
              debugPrint('Konnte Download-Ordner nicht erstellen: $e');
            }
          }
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(jsonString);
          NotificationHelper.showSuccess(
            "${Translator.get('backup_success_android')}\n${file.path}",
          );
        } catch (e) {
          NotificationHelper.showWarning(
            "${Translator.get('backup_fallback_android')}\n$e",
          );
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(jsonString);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: Translator.get('share_text'),
            ),
          );
        }
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: Translator.get('share_text'),
          ),
        );
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_export')} $e");
    }
  }

  /// Opens a file picker for the user to select a JSON backup file and decodes its payload.
  ///
  /// Returns the parsed [Map] containing exported Dexes and data, or `null` if cancelled or invalid.
  static Future<Map<String, dynamic>?> importDexes(DexProvider provider) async {
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: Translator.get('json_files'),
        extensions: const <String>['json'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (file != null) {
        final String jsonString = await file.readAsString();
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          NotificationHelper.showError(
            Translator.get('error_import', fallback: 'Fehler beim Importieren der Datei.'),
          );
          return null;
        }
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_import')} $e");
    }
    return null;
  }
}
