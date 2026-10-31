import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

import '../models/dex_progress_models.dart';
import '../models/user_dex.dart';
import '../utils/notification_helper.dart';
import '../i18n/strings.g.dart';

/// Service responsible for rendering, capturing high-resolution PNGs, saving to disk,
/// sharing via system share sheets, and copying text summaries to clipboard.
class DexCardExportService {
  /// Cleans strings to create valid file names across all operating systems.
  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// Generates an engaging formatted text summary of the living dex achievements
  /// suitable for social media (Twitter/X, Discord, WhatsApp, Reddit).
  static String generateShareText(
    UserDex dex,
    DexProgressStats stats, {
    String language = 'de',
  }) {
    final isEn = language == 'en';
    final countPill = isEn ? 'Caught' : 'Gefangen';
    final boxesCount = dex.customBoxes.isNotEmpty
        ? dex.customBoxes.length
        : (stats.totalCount > 0 ? (stats.totalCount / 30).ceil() : 0);

    final boxesLabel = isEn ? 'Boxes' : 'Boxen';
    final trackedWith = isEn
        ? 'Tracked with PokéVault'
        : 'Getrackt mit PokéVault';

    final buffer = StringBuffer();
    buffer.writeln(
      '🎉 ${dex.title}: ${stats.caughtCount} / ${stats.totalCount} $countPill (${stats.percentage.toStringAsFixed(1)}% COMPLETE)!',
    );
    buffer.writeln(
      '✨ ${stats.shinyCount} Shinies • 🔥 ${stats.alphaCount} Alphas • 📦 $boxesCount $boxesLabel',
    );
    buffer.writeln('$trackedWith #LivingDex #Pokemon');

    return buffer.toString().trim();
  }

  /// Captures a [RepaintBoundary] identified by [repaintBoundaryKey] into PNG byte data.
  ///
  /// Uses [pixelRatio] (default 3.0) for razor-sharp rendering on high-DPI displays.
  static Future<Uint8List?> capturePng(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('RepaintBoundary render object not found');
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('DexCardExportService.capturePng error: $e');
      return null;
    }
  }

  /// Saves [pngBytes] to local storage / Downloads directory and returns the absolute file path.
  static Future<String?> savePngToDisk(
    Uint8List pngBytes, {
    required String dexTitle,
  }) async {
    try {
      final cleanTitle = sanitizeFileName(dexTitle);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'dex_card_${cleanTitle}_$timestamp.png';

      if (kIsWeb) {
        final xFile = XFile.fromData(
          pngBytes,
          name: fileName,
          mimeType: 'image/png',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: t.share_dex_card,
          ),
        );
        NotificationHelper.showSuccess(
          '${t.dex_card_save_success}\n$fileName',
        );
        return fileName;
      }

      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;

      if (isDesktop) {
        try {
          final FileSaveLocation? location = await getSaveLocation(
            suggestedName: fileName,
            acceptedTypeGroups: [
              const XTypeGroup(
                label: 'PNG Images',
                extensions: ['png'],
                mimeTypes: ['image/png'],
              ),
            ],
          );

          if (location != null) {
            final file = File(location.path);
            await file.writeAsBytes(pngBytes);
            NotificationHelper.showSuccess(
              '${t.dex_card_save_success}\n${file.path}',
            );
            return file.path;
          }
        } catch (_) {
          // Fallback to default downloads directory if file dialog is unavailable
        }

        Directory? directory = await getDownloadsDirectory();
        directory ??= await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        NotificationHelper.showSuccess(
          '${t.dex_card_save_success}\n${file.path}',
        );
        return file.path;
      } else if (Platform.isAndroid) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          Directory targetDir = downloadDir;
          if (!await downloadDir.exists()) {
            targetDir = await getApplicationDocumentsDirectory();
          }
          final file = File('${targetDir.path}/$fileName');
          await file.writeAsBytes(pngBytes);
          NotificationHelper.showSuccess(
            '${t.dex_card_save_success}\n${file.path}',
          );
          return file.path;
        } catch (e) {
          // Fallback to temporary directory and share
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pngBytes);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'image/png')],
              text: t.share_dex_card,
            ),
          );
          return file.path;
        }
      } else {
        // iOS or other platforms: write to temp and trigger system share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: t.share_dex_card,
          ),
        );
        return file.path;
      }
    } catch (e) {
      debugPrint('savePngToDisk error: $e');
      NotificationHelper.showError('${t.error} $e');
      return null;
    }
  }

  /// Shares [pngBytes] via the system share sheet (WhatsApp, Discord, Twitter/X, Reddit).
  static Future<void> sharePng(
    Uint8List pngBytes, {
    required String dexTitle,
    required String shareText,
  }) async {
    try {
      final cleanTitle = sanitizeFileName(dexTitle);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'dex_card_${cleanTitle}_$timestamp.png';

      if (kIsWeb) {
        final xFile = XFile.fromData(
          pngBytes,
          name: fileName,
          mimeType: 'image/png',
        );
        await SharePlus.instance.share(ShareParams(files: [xFile], text: shareText));
        return;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText,
        ),
      );
    } catch (e) {
      debugPrint('sharePng error: $e');
      NotificationHelper.showError('${t.error} $e');
    }
  }

  /// Copies [text] to the device clipboard and presents user feedback.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    NotificationHelper.showSuccess(t.dex_card_copy_success);
  }
}
