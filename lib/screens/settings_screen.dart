import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/theme_provider.dart';
import '../providers/dex_provider.dart';
import '../services/dex_storage_service.dart';

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
      appBar: AppBar(title: Text(dexProvider.getText('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(
            context,
            dexProvider.getText('appearance'),
            Icons.palette,
          ),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(dexProvider.getText('dark_mode')),
                  value: dexProvider.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    dexProvider.toggleTheme();
                  },
                ),
                const Divider(height: 1),
                // --- AKZENTFARBE ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dexProvider.getText('choose_accent_color'),
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
                // --- HINTERGRUNDFARBE ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dexProvider.getText('choose_bg_color'),
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
                // --- RESET BUTTON ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextButton.icon(
                    onPressed: () => themeProvider.resetToDefault(),
                    icon: const Icon(Icons.restore),
                    label: Text(
                      dexProvider.getText('reset_theme') != 'reset_theme'
                          ? dexProvider.getText('reset_theme')
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
            dexProvider.getText('general'),
            Icons.language,
          ),
          Card(
            child: ListTile(
              title: Text(dexProvider.getText('language')),
              subtitle: Text(dexProvider.getText('current_language')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, dexProvider),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            dexProvider.getText('data_management'),
            Icons.save,
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(dexProvider.getText('import_tooltip')),
                  onTap: () async => await dexProvider.importJsonData(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: Text(dexProvider.getText('export_tooltip')),
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
    );
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
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(provider.getText('language')),
          children: [
            SimpleDialogOption(
              onPressed: () {
                provider.setLanguage('de');
                Navigator.pop(context);
              },
              child: const Text('  Deutsch (DE)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                provider.setLanguage('en');
                Navigator.pop(context);
              },
              child: const Text('  English (EN)'),
            ),
          ],
        );
      },
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    DexProvider dexProvider,
    bool isDarkMode,
    bool isBackground,
  ) {
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
          // Hier nutzen wir jetzt die gesäuberten Keys!
          title: Text(
            isBackground
                ? dexProvider.getText('choose_bg_color')
                : dexProvider.getText('choose_accent_color'),
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
              child: Text(dexProvider.getText('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                themeProvider.addCustomColor(pickerColor);
                if (isBackground) {
                  themeProvider.updateBackgroundColor(pickerColor, isDarkMode);
                } else {
                  themeProvider.updateThemeColor(pickerColor, isDarkMode);
                }
                Navigator.pop(context);
              },
              child: Text(dexProvider.getText('apply')),
            ),
          ],
        );
      },
    );
  }
}