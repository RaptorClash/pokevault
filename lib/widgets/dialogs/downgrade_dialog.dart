import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../i18n/strings.g.dart';
import '../../utils/notification_helper.dart';
import '../../utils/update_helper.dart';
import '../../services/dex_storage_service.dart';
import '../../providers/dex_provider.dart';

enum DowngradeStep { info, backup, finalWarning, downloading, success }

class DowngradeDialog extends StatefulWidget {
  final UpdateInfo releaseInfo;

  const DowngradeDialog({super.key, required this.releaseInfo});

  @override
  State<DowngradeDialog> createState() => _DowngradeDialogState();
}

class _DowngradeDialogState extends State<DowngradeDialog> {
  DowngradeStep _currentStep = DowngradeStep.info;
  double _progress = 0.0;
  String _savedPath = '';
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep != DowngradeStep.downloading && !_isBackingUp,
      child: AlertDialog(
        title: Text(
          _currentStep == DowngradeStep.backup
              ? t.downgrade_backup_title
              : _currentStep == DowngradeStep.finalWarning
              ? t.downgrade_final_warning_title
              : _currentStep == DowngradeStep.success
              ? 'Download abgeschlossen!'
              : t.attention_downgrade,
          style: TextStyle(
            color: _currentStep == DowngradeStep.finalWarning
                ? Colors.redAccent
                : (_currentStep == DowngradeStep.success ? Colors.green : null),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: _buildContent(context)),
        ),
        actions: _buildActions(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_currentStep == DowngradeStep.success) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Die APK wurde erfolgreich im Downloads-Ordner gespeichert.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'Tipp: Es kann 1-2 Minuten dauern, bis die Datei in der "Dateien"-App deines Handys sichtbar wird.\n\nBitte deinstalliere diese App jetzt und öffne danach die APK, um die alte Version zu installieren.',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gespeichert unter:\n$_savedPath',
            style: const TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (_currentStep == DowngradeStep.info ||
        _currentStep == DowngradeStep.downloading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.releaseInfo.title} (${widget.releaseInfo.version})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: UpdateHelper.filterReleaseNotes(
              widget.releaseInfo.releaseNotes,
              LocaleSettings.currentLocale.languageCode,
            ),
            selectable: true,
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              listBullet:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
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
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.downgrade_warning_text,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          if (_currentStep == DowngradeStep.downloading) ...[
            const SizedBox(height: 24),
            LinearProgressIndicator(value: _progress, color: Colors.red),
            const SizedBox(height: 8),
            Center(child: Text('${(_progress * 100).toStringAsFixed(1)} %')),
          ],
        ],
      );
    } else if (_currentStep == DowngradeStep.backup) {
      return Text(
        t.downgrade_backup_text,
      );
    } else {
      return Text(
        t.downgrade_final_warning_text,
      );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_currentStep == DowngradeStep.downloading) return [];

    if (_currentStep == DowngradeStep.success) {
      return [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Verstanden & Schließen'),
        ),
      ];
    }

    if (_currentStep == DowngradeStep.info) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = DowngradeStep.backup),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            t.downgrade_execute,
          ),
        ),
      ];
    } else if (_currentStep == DowngradeStep.backup) {
      return [
        TextButton(
          onPressed: _isBackingUp
              ? null
              : () => setState(() => _currentStep = DowngradeStep.info),
          child: Text(t.back),
        ),
        TextButton(
          onPressed: _isBackingUp
              ? null
              : () => setState(() => _currentStep = DowngradeStep.finalWarning),
          child: Text(t.downgrade_backup_skip),
        ),
        ElevatedButton(
          onPressed: _isBackingUp
              ? null
              : () async {
                  setState(() => _isBackingUp = true);
                  try {
                    final provider =
                        Provider.of<DexProvider?>(context, listen: false);
                    if (provider != null) {
                      await DexStorageService.exportDexes(
                        provider.userDexes,
                        provider,
                      );
                    }
                    if (mounted) {
                      setState(() {
                        _isBackingUp = false;
                        _currentStep = DowngradeStep.finalWarning;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isBackingUp = false);
                      NotificationHelper.showError('${t.error} $e');
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _isBackingUp
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(t.downgrade_backup_create),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () => setState(() => _currentStep = DowngradeStep.backup),
          child: Text(t.back),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(t.downgrade_final_confirm),
        ),
      ];
    }
  }

  Future<void> _startDownload() async {
    setState(() => _currentStep = DowngradeStep.downloading);
    try {
      String path = await UpdateHelper.downloadOnly(
        widget.releaseInfo.downloadUrl,
        widget.releaseInfo.version,
        widget.releaseInfo.extension,
        (progress) {
          setState(() => _progress = progress);
        },
      );

      if (mounted) {
        setState(() {
          _savedPath = path;
          _currentStep = DowngradeStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentStep = DowngradeStep.info);
        NotificationHelper.showError('${t.error} $e');
      }
    }
  }
}
