import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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

  static Future<List<UpdateInfo>> getAllReleases() async {
    if (kIsWeb) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<UpdateInfo> releases = [];

        for (var release in data) {
          String tagName = release['tag_name'] ?? '';
          String downloadUrl = '';
          String fileExtension = '';

          List assets = release['assets'] ?? [];
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
            releases.add(
              UpdateInfo(
                version: tagName,
                title: release['name'] ?? tagName,
                releaseNotes: release['body'] ?? '',
                downloadUrl: downloadUrl,
                extension: fileExtension,
              ),
            );
          }
        }
        return releases;
      }
    } catch (e) {
      debugPrint('Error fetching all releases: $e');
    }
    return [];
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;

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

  static Future<String> downloadOnly(
    String url,
    String version,
    String extension,
    Function(double) onProgress,
  ) async {
    if (kIsWeb) throw Exception("Nicht im Web unterstützt");
    int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        HttpClient client = HttpClient();
        var request = await client.getUrl(Uri.parse(url));
        var response = await request.close();

        if (response.statusCode == 200) {
          Directory tempDir = await getTemporaryDirectory();
          String savePath = '';

          if (Platform.isAndroid && extension == '.apk') {
            Directory downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              savePath = '${downloadDir.path}/PokeVault_$version$extension';
            } else {
              savePath = '${tempDir.path}/PokeVault_$version$extension';
            }
          } else {
            savePath = '${tempDir.path}/PokeVault_$version$extension';
          }

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
          return savePath;
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
    throw Exception('Download fehlgeschlagen.');
  }

  static Future<void> downloadAndInstallUpdate(
    String url,
    String version,
    String extension,
    Function(double) onProgress,
  ) async {
    if (kIsWeb) return;
    String savePath = await downloadOnly(url, version, extension, onProgress);
    if (Platform.isWindows && extension == '.zip') {
      await _installWindowsUpdate(savePath);
    } else {
      await OpenFilex.open(savePath);
    }
  }

  static Future<void> _installWindowsUpdate(String zipPath) async {
    String exePath = Platform.resolvedExecutable;
    String appDir = File(exePath).parent.path;

    Directory tempDir = await getTemporaryDirectory();
    String batPath = '${tempDir.path}\\update_pokevault.bat';
    String vbsPath = '${tempDir.path}\\run_hidden.vbs';

    String zipW = zipPath.replaceAll('/', '\\');
    String appW = appDir.replaceAll('/', '\\');
    String exeW = exePath.replaceAll('/', '\\');
    String vbsW = vbsPath.replaceAll('/', '\\');

    String batContent =
        '''
@echo off
set RETRIES=0
timeout /t 3 /nobreak > NUL

:Extract
powershell -Command "try { Expand-Archive -Path '$zipW' -DestinationPath '$appW' -Force } catch { exit 1 }" > NUL 2>&1
if %errorlevel% equ 0 goto Success

:Fail
set /a RETRIES+=1
if %RETRIES% geq 5 goto Success
timeout /t 2 /nobreak > NUL
goto Extract

:Success
start "" "$exeW"
del "$zipW"
del "$vbsW"
del "%~f0"
''';
    File batFile = File(batPath);
    await batFile.writeAsString(batContent);

    String vbsContent =
        '''
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$batPath" & chr(34), 0, False
Set WshShell = Nothing
''';
    File vbsFile = File(vbsPath);
    await vbsFile.writeAsString(vbsContent);

    await Process.start('wscript', [vbsPath], mode: ProcessStartMode.detached);
    exit(0);
  }
}
