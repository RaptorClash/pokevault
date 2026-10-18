import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_translations.dart';
import '../../providers/dex_provider.dart';
import '../../services/dex_storage_service.dart';
import '../../utils/notification_helper.dart';
import '../../utils/update_helper.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isBackingUp = false;
  bool _backupDone = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isDownloading && !_isBackingUp,
      child: AlertDialog(
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
                MarkdownBody(
                  data: UpdateHelper.filterReleaseNotes(
                    widget.updateInfo.releaseNotes,
                    Translator.currentLanguage,
                  ),
                  selectable: true,
                  softLineBreak: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    theme,
                  ).copyWith(
                    p: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                    h1: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  onTapLink: (text, href, title) async {
                    if (href != null) {
                      final uri = Uri.tryParse(href);
                      if (uri != null) {
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Could not launch URL: $e');
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isDownloading || _isBackingUp)
                              ? null
                              : () async {
                                  setState(() {
                                    _isBackingUp = true;
                                  });
                                  try {
                                    final provider = Provider.of<DexProvider?>(
                                      context,
                                      listen: false,
                                    );
                                    if (provider != null) {
                                      await DexStorageService.exportDexes(
                                        provider.userDexes,
                                        provider,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          _isBackingUp = false;
                                          _backupDone = true;
                                        });
                                      }
                                    } else {
                                      if (mounted) {
                                        setState(() {
                                          _isBackingUp = false;
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _isBackingUp = false;
                                      });
                                      NotificationHelper.showError(
                                        '${Translator.get('error')} $e',
                                      );
                                    }
                                  }
                                },
                          icon: _isBackingUp
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                )
                              : Icon(
                                  _backupDone
                                      ? Icons.check_circle_outline
                                      : Icons.backup_outlined,
                                  size: 16,
                                  color: _backupDone
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                          label: Text(
                            _backupDone
                                ? Translator.get(
                                    'update_backup_done',
                                    fallback: 'Backup erstellt ✓',
                                  )
                                : Translator.get(
                                    'update_backup_button',
                                    fallback: 'Backup jetzt erstellen',
                                  ),
                            style: TextStyle(
                              fontSize: 13,
                              color: _backupDone
                                  ? Colors.green
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _backupDone
                                  ? Colors.green
                                  : Colors.orange.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
              onPressed: _isBackingUp ? null : () => Navigator.pop(context),
              child: Text(Translator.get('dismiss')),
            ),
          if (!_isDownloading)
            ElevatedButton(
              onPressed: _isBackingUp
                  ? null
                  : () async {
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
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text(Translator.get('download_update')),
            ),
        ],
      ),
    );
  }
}
