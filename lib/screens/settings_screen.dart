import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/dex_provider.dart';
import '../services/dex_storage_service.dart';
import '../l10n/app_translations.dart';
import '../utils/notification_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/update_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Color> _defaultColors = const [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFD81B60),
  ];

  @override
  Widget build(BuildContext context) {
    final dexProvider = context.watch<DexProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
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
                  value: dexProvider.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    dexProvider.toggleTheme();
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
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            Translator.get('updates'),
            Icons.system_update,
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.update),
              title: Text(Translator.get('check_for_updates')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final updateInfo = await UpdateHelper.checkForUpdate();
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
                      NotificationHelper.showInfo(Translator.get('up_to_date'));
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
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            Translator.get('general'),
            Icons.language,
          ),
          Card(
            child: ListTile(
              title: Text(Translator.get('language')),
              subtitle: Text(Translator.get('current_language')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, dexProvider),
            ),
          ),
          const SizedBox(height: 24),

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
          const SizedBox(height: 24),

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
                  onTap: () =>
                      _launchURL('https://github.com/raptorclash/pokevault'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  subtitle: Text(Translator.get('credit_glitch_gen2_sub')),
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
                  leading: const Icon(Icons.memory),
                  title: Text(Translator.get('credit_ai_title')),
                  subtitle: Text(Translator.get('credit_ai_sub')),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => _launchURL('https://gemini.google.com/'),
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
          final isActive = activeColor.value == color.value;
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
                      color: color.withOpacity(0.4),
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
            final dexProvider = Provider.of<DexProvider>(
              context,
              listen: false,
            );
            _showColorPickerDialog(
              context,
              themeProvider,
              dexProvider,
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

  void _showLanguageDialog(BuildContext context, DexProvider provider) {
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
    DexProvider dexProvider,
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
}
