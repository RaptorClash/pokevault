import 'dart:convert';
import 'dart:io';
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
      final List<Map<String, dynamic>> jsonList = dexes
          .map((d) => d.toJson())
          .toList();
      final String jsonString = jsonEncode(jsonList);
      final String dateString = DateTime.now().toIso8601String().split('T')[0];
      final String fileName = 'pokevault_backup_$dateString.json';

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
            await directory.create(recursive: true);
          }
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(jsonString);
          NotificationHelper.showSuccess(
            "${Translator.get('backup_success')}\n${file.path}",
          );
        } catch (e) {
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

  static Future<List<UserDex>?> importDexes(DexProvider provider) async {
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
        final List<dynamic> decoded = jsonDecode(jsonString);

        return decoded.map((item) => UserDex.fromJson(item)).toList();
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_import')} $e");
    }
    return null;
  }
}
