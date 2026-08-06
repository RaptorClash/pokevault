import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/dex_provider.dart';
import 'screens/home_screen.dart';
import 'utils/notification_helper.dart';
import 'dart:ui';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      ChangeNotifierProvider(
        create: (context) => DexProvider(),
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
    final provider = context.watch<DexProvider>();

    return MaterialApp(
      title: 'Modular Pokédex',
      debugShowCheckedModeBanner: false,

      scaffoldMessengerKey: NotificationHelper.scaffoldMessengerKey,
      scrollBehavior: AppScrollBehavior(),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: provider.themeMode,
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
