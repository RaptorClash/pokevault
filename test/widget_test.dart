import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/main.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/theme_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}
class MockTutorialProvider extends Mock implements TutorialProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PokedexApp Smoke Tests', () {
    late MockDexProvider mockDexProvider;
    late MockSettingsProvider mockSettingsProvider;
    late MockTutorialProvider mockTutorialProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LocaleSettings.setLocale(AppLocale.de);

      mockDexProvider = MockDexProvider();
      mockSettingsProvider = MockSettingsProvider();
      mockTutorialProvider = MockTutorialProvider();

      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
      when(() => mockDexProvider.isInitialized).thenReturn(true);
      when(() => mockDexProvider.userDexes).thenReturn([]);
      when(() => mockDexProvider.folders).thenReturn([]);
      when(() => mockDexProvider.structure).thenReturn({'root': []});
      when(() => mockDexProvider.isMigrating).thenReturn(false);
      when(() => mockSettingsProvider.themeMode).thenReturn(ThemeMode.system);
      when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
      when(() => mockSettingsProvider.googleClientId).thenReturn('');
      when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
    });

    testWidgets('Bootstraps PokedexApp and renders home screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
              ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
              ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
            ],
            child: const PokedexApp(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PokedexApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
