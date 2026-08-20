import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_dex.dart';
import '../utils/notification_helper.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';

class DexStorageService {
  static Future<void> exportDexes(
    List<UserDex> dexes,
    DexProvider provider,
  ) async {
    try {
      final Map<String, dynamic> exportData = {
        'dexes': dexes.map((d) => d.toJson()).toList(),
        'folders': provider.folders.map((f) => f.toJson()).toList(),
        'structure': provider.structure,
      };

      final String jsonString = jsonEncode(exportData);
      final String dateString = DateTime.now().toIso8601String().split('T')[0];
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'pokevault_backup_${dateString}_$timestamp.json';

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
          await Share.shareXFiles([
            XFile(file.path),
          ], text: Translator.get('share_text'));
        }
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: Translator.get('share_text'));
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_export')} $e");
    }
  }

  static Future<dynamic> importDexes(DexProvider provider) async {
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
        return jsonDecode(jsonString);
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_import')} $e");
    }
    return null;
  }
}
