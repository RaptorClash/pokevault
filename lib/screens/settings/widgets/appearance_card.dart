import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../l10n/app_translations.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/settings_provider.dart';
import 'settings_helper.dart';

class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  static const List<Color> _defaultColors = [
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
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHelper.buildSectionHeader(
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
                onChanged: (bool value) => settingsProvider.toggleTheme(),
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
                    Translator.get(
                      'reset_theme',
                      fallback: 'Standarddesign wiederherstellen',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          final isActive = activeColor.toARGB32() == color.toARGB32();
          return InkWell(
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
        InkWell(
          onTap: () => _showColorPickerDialog(
            context,
            themeProvider,
            isDarkMode,
            isBackground,
          ),
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

  void _showColorPickerDialog(
    BuildContext context,
    ThemeProvider themeProvider,
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
          title: Text(
            isBackground
                ? Translator.get('choose_bg_color')
                : Translator.get('choose_accent_color'),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
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
                  themeProvider.updateBackgroundColor(pickerColor, isDarkMode);
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
  }
}
