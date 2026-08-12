import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../l10n/app_translations.dart';
import 'notification_helper.dart';

class UpdateInfo {
  final String version;
  final String title;
  final String releaseNotes;
  final String downloadUrl;
  final String extension;

  UpdateInfo({
    required this.version,
    required this.title,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.extension,
  });
}

class UpdateHelper {
  static const String _repoOwner = 'RaptorClash';
  static const String _repoName = 'pokevault';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String tagName = data['tag_name'] ?? '';
        String latestVersion = tagName.replaceAll(RegExp(r'[^0-9.]'), '');

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          String downloadUrl = '';
          String fileExtension = '';
          List assets = data['assets'] ?? [];

          for (var asset in assets) {
            String assetName = asset['name'].toString().toLowerCase();
            if (Platform.isAndroid && assetName.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'];
              fileExtension = '.apk';
              break;
            } else if (Platform.isWindows &&
                (assetName.endsWith('.zip') ||
                    assetName.endsWith('.exe') ||
                    assetName.endsWith('.msix'))) {
              downloadUrl = asset['browser_download_url'];
              fileExtension = assetName.substring(assetName.lastIndexOf('.'));
              break;
            }
          }

          if (downloadUrl.isNotEmpty) {
            return UpdateInfo(
              version: tagName,
              title: data['name'] ?? tagName,
              releaseNotes: data['body'] ?? '',
              downloadUrl: downloadUrl,
              extension: fileExtension,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String current, String latest) {
    String c = current.split('+')[0];
    String l = latest.split('+')[0];
    List<int> currentParts = c
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    List<int> latestParts = l
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      int curr = i < currentParts.length ? currentParts[i] : 0;
      int lat = i < latestParts.length ? latestParts[i] : 0;
      if (lat > curr) return true;
      if (lat < curr) return false;
    }
    return false;
  }

  static Future<void> downloadAndInstallUpdate(
    String url,
    String version,
    String extension,
    Function(double) onProgress,
  ) async {
    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        HttpClient client = HttpClient();
        var request = await client.getUrl(Uri.parse(url));
        var response = await request.close();

        if (response.statusCode == 200) {
          Directory tempDir = await getTemporaryDirectory();
          String savePath =
              '${tempDir.path}/PokeVault_Update_$version$extension';
          File file = File(savePath);
          var sink = file.openWrite();

          int downloaded = 0;
          int contentLength = response.contentLength;

          await for (var chunk in response) {
            sink.add(chunk);
            downloaded += chunk.length;
            if (contentLength > 0) {
              onProgress(downloaded / contentLength);
            }
          }

          await sink.flush();
          await sink.close();

          if (Platform.isWindows && extension == '.zip') {
            await _installWindowsUpdate(savePath);
          } else {
            await OpenFilex.open(savePath);
          }
          return;
        } else {
          throw Exception('HTTP Status Code: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Download attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          throw Exception("Fehler nach $maxRetries Versuchen: $e");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  static Future<void> _installWindowsUpdate(String zipPath) async {
    String exePath = Platform.resolvedExecutable;
    String appDir = File(exePath).parent.path;
    Directory tempDir = await getTemporaryDirectory();
    String batPath = '${tempDir.path}\\update_pokevault.bat';

    String batContent =
        '''
@echo off
echo Warte auf Beendigung der App...
timeout /t 5 /nobreak > NUL
echo Entpacke Update...
tar -m -xf "$zipPath" -C "$appDir"
echo Starte App neu...
start "" "$exePath"
del "$zipPath"
del "%~f0"
''';

    File batFile = File(batPath);
    await batFile.writeAsString(batContent);

    await Process.start('cmd', [
      '/c',
      'start',
      '/min',
      'cmd',
      '/c',
      batPath,
    ], mode: ProcessStartMode.detached);
    exit(0);
  }
}

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Translator.get('update_available_title')),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.updateInfo.title} (${widget.updateInfo.version})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.updateInfo.releaseNotes),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get('update_backup_warning'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isDownloading) ...[
                const SizedBox(height: 24),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Center(
                  child: Text('${(_progress * 100).toStringAsFixed(1)} %'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translator.get('dismiss')),
          ),
        if (!_isDownloading)
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _isDownloading = true;
              });
              try {
                await UpdateHelper.downloadAndInstallUpdate(
                  widget.updateInfo.downloadUrl,
                  widget.updateInfo.version,
                  widget.updateInfo.extension,
                  (progress) {
                    setState(() {
                      _progress = progress;
                    });
                  },
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isDownloading = false;
                  });
                  NotificationHelper.showError('${Translator.get('error')} $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(Translator.get('download_update')),
          ),
      ],
    );
  }
}
