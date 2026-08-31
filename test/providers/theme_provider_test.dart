import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test(
      'Initialzustand besitzt die korrekten Standardfarben für Light und Dark',
      () {
        expect(
          themeProvider.lightPrimaryColor,
          equals(const Color(0xFFE53935)),
        );
        expect(themeProvider.darkPrimaryColor, equals(const Color(0xFF9575CD)));
        expect(themeProvider.customColors, isEmpty);
      },
    );

    test(
      'updateThemeColor ändert die Primärfarbe für Light/Dark Mode',
      () async {
        const newLightColor = Colors.blue;
        const newDarkColor = Colors.purple;

        themeProvider.updateThemeColor(newLightColor, false);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(themeProvider.lightPrimaryColor, equals(newLightColor));

        themeProvider.updateThemeColor(newDarkColor, true);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(themeProvider.darkPrimaryColor, equals(newDarkColor));
      },
    );

    test(
      'addCustomColor fügt neue Farbe hinzu und vermeidet Duplikate',
      () async {
        const customColor = Color(0xFF123456);

        themeProvider.addCustomColor(customColor);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(themeProvider.customColors.length, equals(1));
        expect(themeProvider.customColors.first, equals(customColor));

        themeProvider.addCustomColor(customColor);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(themeProvider.customColors.length, equals(1));
      },
    );

    test(
      'resetToDefault setzt aktive Farbe zurück, behält aber die Custom-Palette',
      () async {
        themeProvider.updateThemeColor(Colors.green, false);
        themeProvider.addCustomColor(const Color(0xFF123456));
        await Future.delayed(const Duration(milliseconds: 50));

        themeProvider.resetToDefault();
        await Future.delayed(const Duration(milliseconds: 50));

        expect(
          themeProvider.lightPrimaryColor,
          equals(const Color(0xFFE53935)),
        );

        expect(themeProvider.customColors, isNotEmpty);
        expect(
          themeProvider.customColors.first,
          equals(const Color(0xFF123456)),
        );
      },
    );
  });
}
