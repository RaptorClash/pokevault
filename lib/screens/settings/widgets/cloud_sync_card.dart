import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_translations.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/dex_provider.dart';
import '../../../../services/google_drive_sync_service.dart';
import '../../../../services/database_service.dart';
import '../../../../utils/notification_helper.dart';
import 'settings_helper.dart';

class CloudSyncCard extends StatefulWidget {
  const CloudSyncCard({super.key});

  @override
  State<CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<CloudSyncCard> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final dexProvider = context.watch<DexProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_sync,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Translator.get('cloud_sync'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                color: Theme.of(context).colorScheme.primary,
                tooltip: Translator.get('cloud_tut_title'),
                onPressed: () => _showCloudSetupTutorial(context),
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller:
                      TextEditingController(
                          text: settingsProvider.googleClientId,
                        )
                        ..selection = TextSelection.collapsed(
                          offset: settingsProvider.googleClientId.length,
                        ),
                  decoration: InputDecoration(
                    labelText: Translator.get('google_client_id'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  onChanged: (val) => settingsProvider.setGoogleClientId(val),
                ),
                const SizedBox(height: 12),
                if (!kIsWeb)
                  TextField(
                    controller:
                        TextEditingController(
                            text: settingsProvider.googleClientSecret,
                          )
                          ..selection = TextSelection.collapsed(
                            offset: settingsProvider.googleClientSecret.length,
                          ),
                    decoration: InputDecoration(
                      labelText: Translator.get('google_client_secret'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    obscureText: true,
                    onChanged: (val) =>
                        settingsProvider.setGoogleClientSecret(val),
                  ),
                if (!kIsWeb) const SizedBox(height: 16),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              GoogleDriveSyncService.instance.isSignedIn
                              ? Colors.red.shade400
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          GoogleDriveSyncService.instance.isSignedIn
                              ? Icons.logout
                              : Icons.login,
                        ),
                        label: FittedBox(
                          child: Text(
                            Translator.get(
                              GoogleDriveSyncService.instance.isSignedIn
                                  ? 'logout_drive'
                                  : 'login_drive',
                            ),
                          ),
                        ),
                        onPressed: () async {
                          if (GoogleDriveSyncService.instance.isSignedIn) {
                            await GoogleDriveSyncService.instance.signOut();
                          } else {
                            if (settingsProvider.googleClientId.isEmpty ||
                                (!kIsWeb &&
                                    settingsProvider
                                        .googleClientSecret
                                        .isEmpty)) {
                              NotificationHelper.showError(
                                "Bitte Anmeldedaten eintragen!",
                              );
                              return;
                            }
                            String result = await GoogleDriveSyncService
                                .instance
                                .signIn(
                                  settingsProvider.googleClientId,
                                  settingsProvider.googleClientSecret,
                                );
                            if (result == "OK") {
                              NotificationHelper.showSuccess(
                                "Login erfolgreich!",
                              );
                            } else {
                              NotificationHelper.showError(
                                "Login fehlgeschlagen: $result",
                              );
                            }
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.sync),
                        label: FittedBox(
                          child: Text(Translator.get('sync_now')),
                        ),
                        onPressed: () async {
                          if (!GoogleDriveSyncService.instance.isSignedIn) {
                            NotificationHelper.showWarning(
                              "Bitte logge dich zuerst ein!",
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          try {
                            final cloudData = await GoogleDriveSyncService
                                .instance
                                .downloadBackup();
                            if (cloudData != null) {
                              await dexProvider.mergeCloudData(cloudData);
                            }
                            final Map<String, dynamic> exportData =
                                await DatabaseService.instance
                                    .exportCloudSyncData();
                            bool success = await GoogleDriveSyncService.instance
                                .uploadBackup(exportData);
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                NotificationHelper.showSuccess(
                                  Translator.get('sync_success'),
                                );
                              } else {
                                NotificationHelper.showError(
                                  "Upload fehlgeschlagen.",
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              NotificationHelper.showError("Sync Fehler: $e");
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCloudSetupTutorial(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Translator.get('cloud_tut_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      Translator.get('cloud_tut_intro'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTutorialStep(
                    context,
                    1,
                    Translator.get('cloud_tut_step1'),
                    linkUrl: 'https://console.cloud.google.com',
                    linkText: '  console.cloud.google.com',
                  ),
                  _buildTutorialStep(
                    context,
                    2,
                    Translator.get('cloud_tut_step2'),
                  ),
                  _buildTutorialStep(
                    context,
                    3,
                    Translator.get('cloud_tut_step3'),
                  ),
                  _buildTutorialStep(
                    context,
                    4,
                    Translator.get('cloud_tut_step4'),
                  ),
                  _buildTutorialStep(
                    context,
                    5,
                    kIsWeb
                        ? Translator.get('cloud_tut_step5_web')
                        : Translator.get('cloud_tut_step5'),
                    isImportant: true,
                  ),
                  _buildTutorialStep(
                    context,
                    6,
                    kIsWeb
                        ? Translator.get('cloud_tut_step6_web')
                        : Translator.get('cloud_tut_step6'),
                  ),
                  _buildTutorialStep(
                    context,
                    7,
                    Translator.get('cloud_tut_step7'),
                  ),
                  _buildTutorialStep(
                    context,
                    8,
                    Translator.get('cloud_tut_step8'),
                  ),
                  _buildTutorialStep(
                    context,
                    9,
                    Translator.get('cloud_tut_step9'),
                  ),
                  _buildTutorialStep(
                    context,
                    10,
                    Translator.get('cloud_tut_step10'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Translator.get('close', fallback: 'Schließen')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTutorialStep(
    BuildContext context,
    int stepNumber,
    String text, {
    bool isImportant = false,
    String? linkUrl,
    String? linkText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isImportant
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isImportant
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isImportant
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
                if (linkUrl != null && linkText != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => SettingsHelper.launchURL(linkUrl),
                    child: Text(
                      linkText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
