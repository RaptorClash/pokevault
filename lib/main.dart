import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'providers/theme_provider.dart';
import 'providers/dex_provider.dart';
import 'providers/tutorial_provider.dart';
import 'screens/home/home_screen.dart';
import 'utils/notification_helper.dart';
import 'l10n/app_translations.dart';
import 'providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i18n/strings.g.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    LocaleSettings.useDeviceLocale();

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    PaintingBinding.instance.imageCache.maximumSize = 150;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 40;

    runApp(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (context) => DexProvider()),
            ChangeNotifierProvider(create: (_) => TutorialProvider(prefs)),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const PokedexApp(),
        ),
      ),
    );
  } catch (e) {
    NotificationHelper.showError("${Translator.get('error')} $e");
  }
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Poke Vault',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: NotificationHelper.scaffoldMessengerKey,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.lightPrimaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: themeProvider.lightBackgroundColor,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.darkPrimaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: themeProvider.darkBackgroundColor,
        useMaterial3: true,
      ),
      themeMode: settingsProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
