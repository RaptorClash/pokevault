import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_translations.dart';
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _currentStep == DowngradeStep.backup
            ? (Translator.get('downgrade_backup_title') !=
                      'downgrade_backup_title'
                  ? Translator.get('downgrade_backup_title')
                  : 'Vorher Backup erstellen?')
            : _currentStep == DowngradeStep.finalWarning
            ? (Translator.get('downgrade_final_warning_title') !=
                      'downgrade_final_warning_title'
                  ? Translator.get('downgrade_final_warning_title')
                  : 'Letzte Warnung')
            : _currentStep == DowngradeStep.success
            ? 'Download abgeschlossen!'
            : (Translator.get('attention_downgrade') != 'attention_downgrade'
                  ? Translator.get('attention_downgrade')
                  : 'Achtung: Downgrade'),
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
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
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
          Text(widget.releaseInfo.releaseNotes),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Translator.get('downgrade_warning_text') !=
                            'downgrade_warning_text'
                        ? Translator.get('downgrade_warning_text')
                        : 'Du bist dabei, auf eine ältere Version der App zurückzukehren. Dabei können neue Funktionen verloren gehen oder Inkompatibilitäten auftreten.\n\nWICHTIG FÜR ANDROID: Android blockiert direkte Downgrades. Du musst die App erst deinstallieren und die heruntergeladene APK manuell installieren.\n\nBitte exportiere VORHER unbedingt deine Dexe in den Einstellungen als Backup!',
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
        Translator.get('downgrade_backup_text') != 'downgrade_backup_text'
            ? Translator.get('downgrade_backup_text')
            : 'Möchtest du deine aktuellen PokéDexe vor dem Downgrade sichern? Das wird dringend empfohlen!',
      );
    } else {
      return Text(
        Translator.get('downgrade_final_warning_text') !=
                'downgrade_final_warning_text'
            ? Translator.get('downgrade_final_warning_text')
            : 'Bist du dir absolut sicher, dass du auf diese alte Version downgraden möchtest? Hast du dein Backup gemacht?',
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
          child: Text(Translator.get('cancel')),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = DowngradeStep.backup),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            Translator.get('downgrade_execute') != 'downgrade_execute'
                ? Translator.get('downgrade_execute')
                : 'Downgrade ausführen',
          ),
        ),
      ];
    } else if (_currentStep == DowngradeStep.backup) {
      return [
        TextButton(
          onPressed: () =>
              setState(() => _currentStep = DowngradeStep.finalWarning),
          child: Text(
            Translator.get('downgrade_backup_skip') != 'downgrade_backup_skip'
                ? Translator.get('downgrade_backup_skip')
                : 'Ohne Backup fortfahren',
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<DexProvider>(context, listen: false);
            await DexStorageService.exportDexes(provider.userDexes, provider);
            if (mounted)
              setState(() => _currentStep = DowngradeStep.finalWarning);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(
            Translator.get('downgrade_backup_create') !=
                    'downgrade_backup_create'
                ? Translator.get('downgrade_backup_create')
                : 'Backup erstellen',
          ),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Translator.get('cancel')),
        ),
        ElevatedButton(
          onPressed: _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            Translator.get('downgrade_final_confirm') !=
                    'downgrade_final_confirm'
                ? Translator.get('downgrade_final_confirm')
                : 'Ja, Downgrade starten',
          ),
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
        NotificationHelper.showError('${Translator.get('error')} $e');
      }
    }
  }
}
