import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
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
            } else if (Platform.isLinux &&
                (assetName.endsWith('.appimage') ||
                    assetName.endsWith('.tar.gz'))) {
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
            } else if (Platform.isLinux &&
                (assetName.endsWith('.appimage') ||
                    assetName.endsWith('.tar.gz'))) {
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
    if (Platform.isWindows && extension.toLowerCase() == '.zip') {
      await _installWindowsUpdate(savePath);
    } else if (Platform.isLinux && extension.toLowerCase() == '.appimage') {
      await _installLinuxUpdate(savePath);
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
:Extract
timeout /t 2 /nobreak > NUL
powershell -Command "try { Expand-Archive -Path '$zipW' -DestinationPath '$appW' -Force } catch { exit 1 }" > NUL 2>&1
if %errorlevel% equ 0 goto Success
set /a RETRIES+=1
if %RETRIES% lss 5 goto Extract
goto Success
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

  static Future<void> _installLinuxUpdate(
    String newFilePath,
  ) async {
    String currentExe = Platform.resolvedExecutable;
    Directory tempDir = await getTemporaryDirectory();
    String shPath = '${tempDir.path}/update_pokevault.sh';

    await Process.run('chmod', ['+x', newFilePath]);

    String appImagePath = Platform.environment['APPIMAGE'] ?? currentExe;

    String shContent =
        '''
#!/bin/sh
sleep 1
cp -f "$newFilePath" "$appImagePath"
chmod +x "$appImagePath"
rm -f "$newFilePath"
nohup "$appImagePath" >/dev/null 2>&1 &
rm -f "$shPath"
''';

    File shFile = File(shPath);
    await shFile.writeAsString(shContent);
    await Process.run('chmod', ['+x', shPath]);

    await Process.start('sh', [shPath], mode: ProcessStartMode.detached);
    exit(0);
  }

  /// Filters the release notes by language.
  /// If the release notes contain language-specific sections (e.g. `## 🇬🇧 English`, `## 🇩🇪 Deutsch`),
  /// only the section matching [targetLang] is shown.
  /// If [targetLang] is not found, it falls back to 'en' (English).
  /// If neither is found or no language headers exist, the original notes are returned.
  static String filterReleaseNotes(String notes, String targetLang) {
    if (notes.trim().isEmpty) return notes;

    final normalizedNotes = notes.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalizedNotes.split('\n');
    final headerRegex = RegExp(r'^(#{1,6})\s+(.+)$');

    // First pass: find all language headers and determine language header level
    int? langHeaderLevel;
    final List<int> langHeaderIndices = [];
    final List<String> langHeaderLangs = [];

    for (int i = 0; i < lines.length; i++) {
      final match = headerRegex.firstMatch(lines[i]);
      if (match != null) {
        final level = match.group(1)!.length;
        final title = match.group(2)!.trim();
        final lang = _detectLanguage(title);

        if (lang != null) {
          if (langHeaderLevel == null) {
            langHeaderLevel = level;
            langHeaderIndices.add(i);
            langHeaderLangs.add(lang);
          } else if (level <= langHeaderLevel) {
            langHeaderIndices.add(i);
            langHeaderLangs.add(lang);
          }
        }
      }
    }

    // If no language headers were found, return the notes as is (with normalized newlines)
    if (langHeaderIndices.isEmpty) {
      return normalizedNotes;
    }

    // Preamble: lines before the first language header
    final preamble = lines.sublist(0, langHeaderIndices.first).join('\n').trim();

    // Parse sections
    final Map<String, String> sections = {};
    String? commonFooter;

    for (int k = 0; k < langHeaderIndices.length; k++) {
      final startIndex = langHeaderIndices[k];
      final currentLang = langHeaderLangs[k];
      int endIndex = lines.length;

      if (k + 1 < langHeaderIndices.length) {
        endIndex = langHeaderIndices[k + 1];
      } else {
        // Last language section: check if there's a common footer after it
        for (int j = startIndex + 1; j < lines.length; j++) {
          final line = lines[j];
          final match = headerRegex.firstMatch(line);
          final isFooterHeader =
              match != null && match.group(1)!.length <= langHeaderLevel!;
          final isGithubChangelog =
              line.trim().startsWith('**Full Changelog**:');
          if (isFooterHeader || isGithubChangelog) {
            endIndex = j;
            commonFooter = lines.sublist(j).join('\n').trim();
            break;
          }
        }
      }

      var sectionLines = lines.sublist(startIndex, endIndex);
      // Remove trailing horizontal rules / dividers and empty lines
      while (sectionLines.isNotEmpty &&
          (sectionLines.last.trim().isEmpty ||
              RegExp(r'^[-*_]{3,}$').hasMatch(sectionLines.last.trim()))) {
        sectionLines = sectionLines.sublist(0, sectionLines.length - 1);
      }
      final sectionText = sectionLines.join('\n').trim();
      sections[currentLang] = sectionText;
    }

    // Select the best matching section:
    // 1. Target language exact / prefix (e.g. 'de' for 'de_DE' / 'de-AT')
    // 2. English ('en')
    // 3. First available language section
    String selectedSection = '';
    final normalizedTarget = targetLang.toLowerCase().trim();
    final cleanTarget = normalizedTarget.split(RegExp(r'[-_]')).first;

    if (sections.containsKey(normalizedTarget)) {
      selectedSection = sections[normalizedTarget]!;
    } else if (sections.containsKey(cleanTarget)) {
      selectedSection = sections[cleanTarget]!;
    } else if (sections.containsKey('en')) {
      selectedSection = sections['en']!;
    } else if (sections.isNotEmpty) {
      selectedSection = sections.values.first;
    }

    // Build final output
    final parts = <String>[];
    if (preamble.isNotEmpty) {
      parts.add(preamble);
    }
    if (selectedSection.isNotEmpty) {
      parts.add(selectedSection);
    }
    if (commonFooter != null && commonFooter.isNotEmpty) {
      parts.add(commonFooter);
    }

    return parts.join('\n\n');
  }

  static bool _hasLangTag(String title, String code) {
    final lower = title.toLowerCase().trim();
    if (lower == code) return true;
    if (RegExp(r'[\[\(\{]' + code + r'[\]\)\}]').hasMatch(lower)) return true;
    if (RegExp(r'^' + code + r'\s*[:\-\–\|\/]').hasMatch(lower)) return true;
    if (RegExp(r'[:\-\–\|\/]\s*' + code + r'$').hasMatch(lower)) return true;
    if (RegExp(r'^' + code + r'\s+').hasMatch(lower)) return true;
    return false;
  }

  static String? _detectLanguage(String title) {
    final lower = title.toLowerCase();

    // German
    if (title.contains('🇩🇪') ||
        title.contains('🇦🇹') ||
        title.contains('🇨🇭') ||
        lower.contains('deutsch') ||
        lower.contains('german') ||
        _hasLangTag(title, 'de')) {
      return 'de';
    }

    // English
    if (title.contains('🇬🇧') ||
        title.contains('🇺🇸') ||
        lower.contains('english') ||
        lower.contains('englisch') ||
        _hasLangTag(title, 'en')) {
      return 'en';
    }

    // Spanish
    if (title.contains('🇪🇸') ||
        title.contains('🇲🇽') ||
        lower.contains('español') ||
        lower.contains('espanol') ||
        lower.contains('spanish') ||
        _hasLangTag(title, 'es')) {
      return 'es';
    }

    // French
    if (title.contains('🇫🇷') ||
        lower.contains('français') ||
        lower.contains('francais') ||
        lower.contains('french') ||
        _hasLangTag(title, 'fr')) {
      return 'fr';
    }

    // Italian
    if (title.contains('🇮🇹') ||
        lower.contains('italiano') ||
        lower.contains('italian') ||
        _hasLangTag(title, 'it')) {
      return 'it';
    }

    // Japanese
    if (title.contains('🇯🇵') ||
        lower.contains('japanese') ||
        lower.contains('japanisch') ||
        title.contains('日本語') ||
        _hasLangTag(title, 'ja')) {
      return 'ja';
    }

    return null;
  }
}
