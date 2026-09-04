import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../../services/google_drive_sync_service.dart';
import 'downgrade_screen.dart';
import '../../providers/theme_provider.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../services/dex_storage_service.dart';
import '../../l10n/app_translations.dart';
import '../../utils/notification_helper.dart';
import '../../utils/update_helper.dart';
import '../../widgets/dialogs/update_dialog.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Color> _defaultColors = const [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFD81B60),
  ];

  final GlobalKey _appearanceKey = GlobalKey();
  final GlobalKey _updatesKey = GlobalKey();
  final GlobalKey _generalKey = GlobalKey();
  final GlobalKey _dataKey = GlobalKey();
  final GlobalKey _cloudKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();
  final GlobalKey _creditsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  void _showTutorialIfNeeded() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);

    if (!tutProvider.hasSeenFeature('settings_screen')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'settings_screen',
          nameKey: 'settings',
          steps: [
            TutorialStep(
              targetKey: _appearanceKey,
              titleKey: 'tutorial_settings_appearance_title',
              textKey: 'tutorial_settings_appearance_text',
            ),
            TutorialStep(
              targetKey: _updatesKey,
              titleKey: 'tutorial_settings_updates_title',
              textKey: 'tutorial_settings_updates_text',
            ),
            TutorialStep(
              targetKey: _generalKey,
              titleKey: 'tutorial_settings_general_title',
              textKey: 'tutorial_settings_general_text',
            ),
            TutorialStep(
              targetKey: _dataKey,
              titleKey: 'tutorial_settings_data_title',
              textKey: 'tutorial_settings_data_text',
            ),
            TutorialStep(
              targetKey: _cloudKey,
              titleKey: 'tutorial_settings_cloud_title',
              textKey: 'tutorial_settings_cloud_text',
            ),
            TutorialStep(
              targetKey: _communityKey,
              titleKey: 'tutorial_settings_community_title',
              textKey: 'tutorial_settings_community_text',
            ),
            TutorialStep(
              targetKey: _creditsKey,
              titleKey: 'tutorial_settings_credits_title',
              textKey: 'tutorial_settings_credits_text',
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('settings_screen'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dexProvider = context.watch<DexProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            key: _appearanceKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(
                  context,
                  Translator.get('appearance'),
                  Icons.palette,
                ),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: Text(Translator.get('dark_mode')),
                        value: settingsProvider.themeMode == ThemeMode.dark,
                        onChanged: (bool value) {
                          settingsProvider.toggleTheme();
                        },
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Translator.get('choose_accent_color'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildColorList(
                              context,
                              themeProvider,
                              isDarkMode,
                              isBackground: false,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Translator.get('choose_bg_color'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildColorList(
                              context,
                              themeProvider,
                              isDarkMode,
                              isBackground: true,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: TextButton.icon(
                          onPressed: () => themeProvider.resetToDefault(),
                          icon: const Icon(Icons.restore),
                          label: Text(
                            Translator.get('reset_theme') != 'reset_theme'
                                ? Translator.get('reset_theme')
                                : 'Standarddesign wiederherstellen',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            key: _updatesKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(
                  context,
                  Translator.get('updates'),
                  Icons.system_update,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.update),
                        title: Text(Translator.get('check_for_updates')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          try {
                            final updateInfo =
                                await UpdateHelper.checkForUpdate();
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (updateInfo != null) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                      UpdateDialog(updateInfo: updateInfo),
                                );
                              } else {
                                NotificationHelper.showInfo(
                                  Translator.get('up_to_date'),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              NotificationHelper.showError(
                                '${Translator.get('error')} $e',
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.history,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          Translator.get('downgrades_title') !=
                                  'downgrades_title'
                              ? Translator.get('downgrades_title')
                              : 'Vorherige Versionen (Downgrades)',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DowngradeScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            key: _generalKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(
                  context,
                  Translator.get('general'),
                  Icons.language,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(Translator.get('language')),
                        subtitle: Text(Translator.get('current_language')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () =>
                            _showLanguageDialog(context, settingsProvider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                        ),
                        title: Text(
                          Translator.get('tutorial_reset_title') !=
                                  'tutorial_reset_title'
                              ? Translator.get('tutorial_reset_title')
                              : 'Tutorial neustarten',
                        ),
                        subtitle: Text(
                          Translator.get('tutorial_reset_sub') !=
                                  'tutorial_reset_sub'
                              ? Translator.get('tutorial_reset_sub')
                              : 'Setzt alle Hilfen zurück',
                        ),
                        onTap: () async {
                          try {
                            final tutProvider = Provider.of<TutorialProvider>(
                              context,
                              listen: false,
                            );
                            await tutProvider.resetAllTutorials();
                            NotificationHelper.showSuccess(
                              Translator.get('tutorial_reset_success') !=
                                      'tutorial_reset_success'
                                  ? Translator.get('tutorial_reset_success')
                                  : 'Tutorial wurde zurückgesetzt!',
                            );
                          } catch (e) {
                            NotificationHelper.showError(
                              '${Translator.get('error')} $e',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            key: _dataKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(
                  context,
                  Translator.get('data_management'),
                  Icons.save,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: Text(Translator.get('import_tooltip')),
                        onTap: () async => await dexProvider.importJsonData(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.upload),
                        title: Text(Translator.get('export_tooltip')),
                        onTap: () async {
                          if (dexProvider.userDexes.isNotEmpty) {
                            await DexStorageService.exportDexes(
                              dexProvider.userDexes,
                              dexProvider,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            key: _cloudKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8.0,
                    left: 8.0,
                    right: 8.0,
                  ),
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
                                  offset:
                                      settingsProvider.googleClientId.length,
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
                          onChanged: (val) =>
                              settingsProvider.setGoogleClientId(val),
                        ),
                        const SizedBox(height: 12),
                        if (!kIsWeb)
                          TextField(
                            controller:
                                TextEditingController(
                                    text: settingsProvider.googleClientSecret,
                                  )
                                  ..selection = TextSelection.collapsed(
                                    offset: settingsProvider
                                        .googleClientSecret
                                        .length,
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
                                  if (GoogleDriveSyncService
                                      .instance
                                      .isSignedIn) {
                                    await GoogleDriveSyncService.instance
                                        .signOut();
                                  } else {
                                    if (settingsProvider
                                            .googleClientId
                                            .isEmpty ||
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
                                  if (!GoogleDriveSyncService
                                      .instance
                                      .isSignedIn) {
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
                                    final cloudData =
                                        await GoogleDriveSyncService.instance
                                            .downloadBackup();
                                    if (cloudData != null) {
                                      await dexProvider.mergeCloudData(
                                        cloudData,
                                      );
                                    }
                                    final Map<String, dynamic> exportData =
                                        await DatabaseService.instance
                                            .exportCloudSyncData();
                                    bool success = await GoogleDriveSyncService
                                        .instance
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
                                      NotificationHelper.showError(
                                        "Sync Fehler: $e",
                                      );
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
            ),
          ),
          const SizedBox(height: 24),

          Container(
            key: _communityKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(
                  context,
                  Translator.get('community_support'),
                  Icons.people_alt,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bug_report_outlined),
                        title: Text(Translator.get('report_issue_title')),
                        subtitle: Text(Translator.get('report_issue_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://github.com/raptorclash/pokevault/issues/new/choose',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: Text(Translator.get('contribute_title')),
                        subtitle: Text(Translator.get('contribute_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://github.com/raptorclash/pokevault',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            key: _creditsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(
                  context,
                  Translator.get('credits'),
                  Icons.favorite_rounded,
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.api_rounded),
                        title: Text(Translator.get('credit_api_title')),
                        subtitle: Text(Translator.get('credit_api_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL('https://pokeapi.co/'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lightbulb_outline_rounded),
                        title: Text(Translator.get('credit_inspi_title')),
                        subtitle: Text(Translator.get('credit_inspi_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text(Translator.get('credit_pokewiki_title')),
                        subtitle: Text(Translator.get('credit_pokewiki_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL('https://www.pokewiki.de/'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.article),
                        title: Text(Translator.get('credit_bisafans_title')),
                        subtitle: Text(Translator.get('credit_bisafans_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL('https://www.bisafans.de/'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: Text(Translator.get('credit_shiny_gen1_title')),
                        subtitle: Text(Translator.get('credit_shiny_gen1_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://bluemoonfalls.com/pages/shinies/gen-1-shiny-hunting',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.bug_report_rounded),
                        title: Text(Translator.get('credit_glitch_gen2_title')),
                        subtitle: Text(
                          Translator.get('credit_glitch_gen2_sub'),
                        ),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.catching_pokemon),
                        title: Text(Translator.get('credit_balls_title')),
                        subtitle: Text(Translator.get('credit_balls_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.menu_book_rounded),
                        title: const Text('Bulbapedia (Catch Rates)'),
                        subtitle: const Text(
                          'Mechaniken für Legends Z-A und Max Raids',
                        ),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL(
                          'https://bulbapedia.bulbagarden.net/wiki/Catch_rate',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.memory),
                        title: Text(Translator.get('credit_ai_title')),
                        subtitle: Text(Translator.get('credit_ai_sub')),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchURL('https://gemini.google.com/'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final packageInfo = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: Text(
                      'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        NotificationHelper.showError(
          "${Translator.get('error_launch_url')} $urlString",
        );
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_launch_url')} $e");
    }
  }

  Widget _buildColorList(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDarkMode, {
    required bool isBackground,
  }) {
    Color activeColor = isBackground
        ? (isDarkMode
              ? themeProvider.darkBackgroundColor
              : themeProvider.lightBackgroundColor)
        : (isDarkMode
              ? themeProvider.darkPrimaryColor
              : themeProvider.lightPrimaryColor);

    List<Color> allColorsToDisplay = [
      ..._defaultColors,
      ...themeProvider.customColors,
    ];

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: [
        ...allColorsToDisplay.map((color) {
          final isActive = activeColor.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () {
              if (isBackground) {
                themeProvider.updateBackgroundColor(color, isDarkMode);
              } else {
                themeProvider.updateThemeColor(color, isDarkMode);
              }
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isActive
                  ? Icon(
                      Icons.check,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    )
                  : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () {
            _showColorPickerDialog(
              context,
              themeProvider,
              isDarkMode,
              isBackground,
            );
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(Translator.get('language')),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  provider.setLanguage('de');
                  Navigator.pop(context);
                },
                child: const Text('🇩🇪 Deutsch (DE)'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  provider.setLanguage('en');
                  Navigator.pop(context);
                },
                child: const Text('🇬🇧 English (EN)'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_show_language_dialog')} $e",
      );
    }
  }

  void _showColorPickerDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDarkMode,
    bool isBackground,
  ) {
    try {
      Color pickerColor = isBackground
          ? (isDarkMode
                ? themeProvider.darkBackgroundColor
                : themeProvider.lightBackgroundColor)
          : (isDarkMode
                ? themeProvider.darkPrimaryColor
                : themeProvider.lightPrimaryColor);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              isBackground
                  ? Translator.get('choose_bg_color')
                  : Translator.get('choose_accent_color'),
            ),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
                pickerAreaHeightPercent: 0.8,
                enableAlpha: true,
                displayThumbColor: true,
                hexInputBar: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(Translator.get('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  themeProvider.addCustomColor(pickerColor);
                  if (isBackground) {
                    themeProvider.updateBackgroundColor(
                      pickerColor,
                      isDarkMode,
                    );
                  } else {
                    themeProvider.updateThemeColor(pickerColor, isDarkMode);
                  }
                  Navigator.pop(context);
                },
                child: Text(Translator.get('apply')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      NotificationHelper.showError(
        "${Translator.get('error_show_colorpicker_dialog')} $e",
      );
    }
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
                    linkText: '🔗 console.cloud.google.com',
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
              child: Text(
                Translator.get('close') != 'close'
                    ? Translator.get('close')
                    : 'Schließen',
              ),
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
                    onTap: () => _launchURL(linkUrl),
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
