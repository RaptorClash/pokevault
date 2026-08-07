import 'package:flutter/material.dart';
import 'package:pokevault/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'providers/dex_provider.dart';
import 'screens/home_screen.dart';
import 'utils/notification_helper.dart';
import 'dart:ui';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => DexProvider()),
        ],
        child: const PokedexApp(),
      ),
    );
  } catch (e) {
    NotificationHelper.showError("Fehler beim Starten der App: $e");
  }
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dexProvider = context.watch<DexProvider>();
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PokéVault',
      debugShowCheckedModeBanner: false,

      scaffoldMessengerKey: NotificationHelper.scaffoldMessengerKey,
      scrollBehavior: AppScrollBehavior(),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.lightPrimaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor:
            themeProvider.lightBackgroundColor,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.darkPrimaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor:
            themeProvider.darkBackgroundColor,
        useMaterial3: true,
      ),
      themeMode: dexProvider.themeMode,
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
