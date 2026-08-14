import 'package:flutter/material.dart';
import '../../l10n/app_translations.dart';
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
