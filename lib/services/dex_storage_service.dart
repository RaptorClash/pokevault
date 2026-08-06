import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_dex.dart';
import '../utils/notification_helper.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/dex_provider.dart';

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
          "${provider.getText('backup_success')}\n${file.path}",
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: provider.getText('share_text'));
      }
    } catch (e) {
      NotificationHelper.showError("${provider.getText('error_export')} $e");
    }
  }

  static Future<List<UserDex>?> importDexes(DexProvider provider) async {
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: provider.getText('json_files'),
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
      NotificationHelper.showError("${provider.getText('error_import')} $e");
    }
    return null;
  }
}
