import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/providers/theme_provider.dart';
import 'package:pokevault/screens/settings/settings_screen.dart';
import 'package:pokevault/screens/settings/downgrade_screen.dart';
import 'package:pokevault/screens/settings/tutorial_settings_screen.dart';
import 'package:pokevault/screens/settings/widgets/appearance_card.dart';
import 'package:pokevault/screens/settings/widgets/cloud_sync_card.dart';
import 'package:pokevault/screens/settings/widgets/misc_settings_cards.dart';
import 'package:pokevault/screens/settings/widgets/settings_helper.dart';
import 'package:pokevault/widgets/dialogs/downgrade_dialog.dart';
import 'package:pokevault/widgets/dialogs/update_dialog.dart';
import 'package:pokevault/widgets/tutorial/chapter_demo_dialog.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

class _FakeUrlLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;

  @override
  Future<bool> canLaunch(String url) async => true;
}

class MockThemeProvider extends Mock implements ThemeProvider {}

class _MockHttpOverrides extends HttpOverrides {
  final String responseBody;
  final int statusCode;

  _MockHttpOverrides({this.responseBody = '[]', this.statusCode = 200});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(responseBody: responseBody, statusCode: statusCode);
  }
}

class _FakeHttpClient implements HttpClient {
  final String responseBody;
  final int statusCode;
  @override
  bool autoUncompress = true;

  _FakeHttpClient({required this.responseBody, required this.statusCode});

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpClientRequest(responseBody: responseBody, statusCode: statusCode);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => openUrl('GET', url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final String responseBody;
  final int statusCode;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  _FakeHttpClientRequest({required this.responseBody, required this.statusCode});

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(responseBody: responseBody, statusCode: statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes;
  @override
  final int statusCode;

  _FakeHttpClientResponse({required String responseBody, required this.statusCode})
      : _bytes = utf8.encode(responseBody);

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockTutorialProvider mockTutorialProvider;
  late MockThemeProvider mockThemeProvider;

  setUpAll(() {
    registerFallbackValue(const Color(0xFF000000));
    UrlLauncherPlatform.instance = _FakeUrlLauncher();
  });

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Pokevault',
      packageName: 'com.example.pokevault',
      version: '1.5.0',
      buildNumber: '6',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocale(AppLocale.de);

    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockTutorialProvider = MockTutorialProvider();
    mockThemeProvider = MockThemeProvider();

    // Default ThemeProvider stubs
    when(() => mockThemeProvider.darkBackgroundColor).thenReturn(const Color(0xFF121212));
    when(() => mockThemeProvider.lightBackgroundColor).thenReturn(const Color(0xFFF7F7F8));
    when(() => mockThemeProvider.darkPrimaryColor).thenReturn(const Color(0xFF9575CD));
    when(() => mockThemeProvider.lightPrimaryColor).thenReturn(const Color(0xFFE53935));
    when(() => mockThemeProvider.customColors).thenReturn([const Color(0xFF336699)]);
    when(() => mockThemeProvider.updateBackgroundColor(any(), any())).thenAnswer((_) async {});
    when(() => mockThemeProvider.updateThemeColor(any(), any())).thenAnswer((_) async {});
    when(() => mockThemeProvider.addCustomColor(any())).thenAnswer((_) async {});
    when(() => mockThemeProvider.resetToDefault()).thenAnswer((_) async {});

    // Default SettingsProvider stubs
    when(() => mockSettingsProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockSettingsProvider.toggleTheme()).thenAnswer((_) async {});
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    when(() => mockSettingsProvider.googleClientId).thenReturn('');
    when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
    when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
    when(() => mockSettingsProvider.setGoogleClientId(any())).thenAnswer((_) async {});
    when(() => mockSettingsProvider.setGoogleClientSecret(any())).thenAnswer((_) async {});
    when(() => mockSettingsProvider.setLanguage(any())).thenAnswer((_) async {});

    // Default TutorialProvider stubs
    when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    when(() => mockTutorialProvider.resetAllTutorials()).thenAnswer((_) async {});
    when(() => mockTutorialProvider.resetTutorial(any())).thenAnswer((_) async {});
    when(() => mockTutorialProvider.markFeatureAsSeen(any())).thenAnswer((_) async {});

    // Default DexProvider stubs
    when(() => mockDexProvider.userDexes).thenReturn([]);
    when(() => mockDexProvider.folders).thenReturn([]);
    when(() => mockDexProvider.structure).thenReturn({});
    when(() => mockDexProvider.importJsonData()).thenAnswer((_) async {});
  });

  Widget buildApp({required Widget child, bool isDark = false, bool isScreen = false}) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: isScreen ? child : Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  group('SettingsScreen Core Tests', () {
    testWidgets('SettingsScreen renders AppBar, all sections, and package version', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildApp(child: const SettingsScreen(), isScreen: true));
      await tester.pumpAndSettle();

      expect(find.text(t.settings), findsOneWidget);
      expect(find.byType(AppearanceCard), findsOneWidget);
      expect(find.byType(UpdatesCard), findsOneWidget);
      expect(find.byType(GeneralCard), findsOneWidget);
      expect(find.byType(DataManagementCard), findsOneWidget);
      expect(find.byType(CloudSyncCard), findsOneWidget);
      expect(find.byType(CommunityCard), findsOneWidget);
      expect(find.byType(CreditsCard), findsOneWidget);

      // Verify version text
      expect(find.text('Version 1.5.0 (Build 6)'), findsOneWidget);
    });

    testWidgets('SettingsScreen triggers tutorial when hasSeenFeature is false', (tester) async {
      when(() => mockTutorialProvider.hasSeenFeature('settings_screen')).thenReturn(false);

      await tester.pumpWidget(buildApp(child: const SettingsScreen(), isScreen: true));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockTutorialProvider.hasSeenFeature('settings_screen')).called(1);
    });
  });

  group('AppearanceCard Tests', () {
    testWidgets('AppearanceCard renders dark mode switch and toggles theme on tap', (tester) async {
      when(() => mockSettingsProvider.themeMode).thenReturn(ThemeMode.light);

      await tester.pumpWidget(buildApp(child: const AppearanceCard()));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      verify(() => mockSettingsProvider.toggleTheme()).called(1);
    });

    testWidgets('Tapping color circles updates theme colors', (tester) async {
      await tester.pumpWidget(buildApp(child: const AppearanceCard()));
      await tester.pumpAndSettle();

      // Find color inkwells
      final inkWells = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsWidgets);

      // Tap first color item (accent color)
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      verify(() => mockThemeProvider.updateThemeColor(any(), false)).called(1);
    });

    testWidgets('Tapping background color circle updates background color', (tester) async {
      await tester.pumpWidget(buildApp(child: const AppearanceCard(key: Key('app_card'))));
      await tester.pumpAndSettle();

      // Second wrap is for background colors
      final wraps = find.byType(Wrap);
      expect(wraps, findsNWidgets(2));

      final bgInkWells = find.descendant(
        of: wraps.at(1),
        matching: find.byType(InkWell),
      );
      await tester.tap(bgInkWells.first);
      await tester.pumpAndSettle();

      verify(() => mockThemeProvider.updateBackgroundColor(any(), false)).called(1);
    });

    testWidgets('Tapping add color opens color picker dialog and applying adds custom color', (tester) async {
      await tester.pumpWidget(buildApp(child: const AppearanceCard()));
      await tester.pumpAndSettle();

      // Tap '+' button in the first Wrap
      final addIcons = find.byIcon(Icons.add);
      expect(addIcons, findsNWidgets(2));

      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // Verify color picker dialog is open
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text(t.choose_accent_color)),
        findsOneWidget,
      );
      expect(find.text(t.apply), findsOneWidget);
      expect(find.text(t.cancel), findsOneWidget);

      // Tap apply
      await tester.tap(find.text(t.apply));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => mockThemeProvider.addCustomColor(any())).called(1);
      verify(() => mockThemeProvider.updateThemeColor(any(), false)).called(1);
    });

    testWidgets('Tapping cancel on color picker dialog dismisses without applying', (tester) async {
      await tester.pumpWidget(buildApp(child: const AppearanceCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(t.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockThemeProvider.addCustomColor(any()));
    });

    testWidgets('Tapping add color on background color wrap opens bg color dialog and applies', (tester) async {
      await tester.pumpWidget(buildApp(child: const AppearanceCard()));
      await tester.pumpAndSettle();

      final addIcons = find.byIcon(Icons.add);
      await tester.tap(addIcons.last);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text(t.choose_bg_color)),
        findsOneWidget,
      );

      await tester.tap(find.text(t.apply));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => mockThemeProvider.addCustomColor(any())).called(1);
      verify(() => mockThemeProvider.updateBackgroundColor(any(), false)).called(1);
    });

    testWidgets('Tapping reset theme calls resetToDefault', (tester) async {
      await tester.pumpWidget(buildApp(child: const AppearanceCard()));
      await tester.pumpAndSettle();

      final resetBtn = find.widgetWithText(TextButton, t.reset_theme);
      expect(resetBtn, findsOneWidget);

      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      verify(() => mockThemeProvider.resetToDefault()).called(1);
    });
  });

  group('GeneralCard Tests', () {
    testWidgets('Language selection dialog sets language to German and English', (tester) async {
      await tester.pumpWidget(buildApp(child: const GeneralCard()));
      await tester.pumpAndSettle();

      final langTile = find.widgetWithText(ListTile, t.language);
      expect(langTile, findsOneWidget);

      // Open language dialog
      await tester.tap(langTile);
      await tester.pumpAndSettle();

      expect(find.text('  Deutsch (DE)'), findsOneWidget);
      expect(find.text('  English (EN)'), findsOneWidget);

      // Select German
      await tester.tap(find.text('  Deutsch (DE)'));
      await tester.pumpAndSettle();
      verify(() => mockSettingsProvider.setLanguage('de')).called(1);

      // Open again and select English
      await tester.tap(langTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('  English (EN)'));
      await tester.pumpAndSettle();
      verify(() => mockSettingsProvider.setLanguage('en')).called(1);
    });

    testWidgets('Tutorial center tile opens TutorialSettingsScreen', (tester) async {
      when(() => mockTutorialProvider.isChapterCompleted(any())).thenReturn(true);
      await tester.pumpWidget(buildApp(child: const GeneralCard()));
      await tester.pumpAndSettle();

      final tutCenterTile = find.widgetWithText(
        ListTile,
        t.tutorial_center_title,
      );
      expect(tutCenterTile, findsOneWidget);

      await tester.tap(tutCenterTile);
      await tester.pumpAndSettle();

      expect(find.byType(TutorialSettingsScreen), findsOneWidget);
    });
  });

  group('DataManagementCard Tests', () {
    testWidgets('Import JSON tile calls dexProvider.importJsonData', (tester) async {
      await tester.pumpWidget(buildApp(child: const DataManagementCard()));
      await tester.pumpAndSettle();

      final importTile = find.widgetWithText(ListTile, t.import_tooltip);
      expect(importTile, findsOneWidget);

      await tester.tap(importTile);
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.importJsonData()).called(1);
    });

    testWidgets('Export JSON tile does nothing if userDexes is empty', (tester) async {
      when(() => mockDexProvider.userDexes).thenReturn([]);

      await tester.pumpWidget(buildApp(child: const DataManagementCard()));
      await tester.pumpAndSettle();

      final exportTile = find.widgetWithText(ListTile, t.export_tooltip);
      expect(exportTile, findsOneWidget);

      await tester.tap(exportTile);
      await tester.pumpAndSettle();
    });
  });

  group('CloudSyncCard Tests', () {
    testWidgets('Editing Google Client ID calls setGoogleClientId', (tester) async {
      await tester.pumpWidget(buildApp(child: const CloudSyncCard()));
      await tester.pumpAndSettle();

      final clientIdField = find.widgetWithText(TextField, t.google_client_id);
      expect(clientIdField, findsOneWidget);

      await tester.enterText(clientIdField, 'new_client_id_123');
      await tester.pumpAndSettle();

      verify(() => mockSettingsProvider.setGoogleClientId('new_client_id_123')).called(1);
    });

    testWidgets('Editing Google Client Secret calls setGoogleClientSecret', (tester) async {
      await tester.pumpWidget(buildApp(child: const CloudSyncCard()));
      await tester.pumpAndSettle();

      final clientSecretField = find.widgetWithText(TextField, t.google_client_secret);
      expect(clientSecretField, findsOneWidget);

      await tester.enterText(clientSecretField, 'new_secret_456');
      await tester.pumpAndSettle();

      verify(() => mockSettingsProvider.setGoogleClientSecret('new_secret_456')).called(1);
    });

    testWidgets('Tapping help icon opens cloud setup tutorial dialog with 10 steps and closes it', (tester) async {
      await tester.pumpWidget(buildApp(child: const CloudSyncCard()));
      await tester.pumpAndSettle();

      final helpBtn = find.byIcon(Icons.help_outline);
      expect(helpBtn, findsOneWidget);

      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.text(t.cloud_tut_title), findsWidgets);
      expect(find.text(t.cloud_tut_intro), findsOneWidget);
      expect(find.text(t.close), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text(t.close));
      await tester.pumpAndSettle();

      expect(find.text(t.cloud_tut_intro), findsNothing);
    });

    testWidgets('Tapping login with empty credentials shows error notification', (tester) async {
      when(() => mockSettingsProvider.googleClientId).thenReturn('');
      when(() => mockSettingsProvider.googleClientSecret).thenReturn('');

      await tester.pumpWidget(buildApp(child: const CloudSyncCard()));
      await tester.pumpAndSettle();

      final loginBtn = find.widgetWithText(ElevatedButton, t.login_drive);
      expect(loginBtn, findsOneWidget);

      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping sync now while signed out shows warning notification', (tester) async {
      await tester.pumpWidget(buildApp(child: const CloudSyncCard()));
      await tester.pumpAndSettle();

      final syncBtn = find.widgetWithText(ElevatedButton, t.sync_now);
      expect(syncBtn, findsOneWidget);

      await tester.tap(syncBtn);
      await tester.pumpAndSettle();
    });
  });

  group('UpdatesCard & DowngradeScreen Tests', () {
    testWidgets('UpdatesCard renders tiles and tapping Downgrades opens DowngradeScreen', (tester) async {
      HttpOverrides.global = _MockHttpOverrides(responseBody: '[]');

      await tester.pumpWidget(buildApp(child: const UpdatesCard()));
      await tester.pumpAndSettle();

      expect(find.text(t.check_for_updates), findsOneWidget);

      final downgradeTile = find.widgetWithText(
        ListTile,
        t.downgrades_title,
      );
      expect(downgradeTile, findsOneWidget);

      await tester.tap(downgradeTile);
      await tester.pumpAndSettle();

      expect(find.byType(DowngradeScreen), findsOneWidget);
      HttpOverrides.global = null;
    });

    testWidgets('UpdatesCard check for updates handles up to date response', (tester) async {
      HttpOverrides.global = _MockHttpOverrides(
        responseBody: jsonEncode({
          'tag_name': 'v1.0.0',
          'name': 'v1.0.0',
          'assets': [],
        }),
      );

      await tester.pumpWidget(buildApp(child: const UpdatesCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.check_for_updates));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      HttpOverrides.global = null;
    });

    testWidgets('UpdatesCard check for updates handles update available and opens UpdateDialog', (tester) async {
      HttpOverrides.global = _MockHttpOverrides(
        responseBody: jsonEncode({
          'tag_name': 'v2.0.0',
          'name': 'v2.0.0',
          'body': 'Major release notes',
          'assets': [
            {
              'name': 'pokevault.zip',
              'browser_download_url': 'https://github.com/RaptorClash/pokevault/releases/download/v2.0.0/pokevault.zip',
            }
          ],
        }),
      );

      await tester.pumpWidget(buildApp(child: const UpdatesCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.check_for_updates));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
      expect(find.text(t.update_available_title), findsOneWidget);

      HttpOverrides.global = null;
    });

    testWidgets('UpdatesCard check for updates handles network error gracefully', (tester) async {
      HttpOverrides.global = _MockHttpOverrides(
        responseBody: 'Internal Server Error',
        statusCode: 500,
      );

      await tester.pumpWidget(buildApp(child: const UpdatesCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.check_for_updates));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      HttpOverrides.global = null;
    });

    testWidgets('DowngradeScreen handles HTTP error by displaying empty state', (tester) async {
      HttpOverrides.global = _MockHttpOverrides(
        responseBody: 'Error',
        statusCode: 500,
      );

      await tester.pumpWidget(buildApp(child: const DowngradeScreen(), isScreen: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Keine älteren Versionen gefunden.'), findsOneWidget);
      HttpOverrides.global = null;
    });

    testWidgets('DowngradeScreen displays empty state when no older releases found', (tester) async {
      HttpOverrides.global = _MockHttpOverrides(responseBody: '[]');

      await tester.pumpWidget(buildApp(child: const DowngradeScreen(), isScreen: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Keine älteren Versionen gefunden.'), findsOneWidget);
      HttpOverrides.global = null;
    });

    testWidgets('DowngradeScreen displays older releases and tapping opens DowngradeDialog', (tester) async {
      final fakeReleases = [
        {
          'tag_name': 'v1.0.0',
          'name': 'Pokevault 1.0.0',
          'body': 'Initial release notes',
          'assets': [
            {
              'name': 'pokevault.zip',
              'browser_download_url': 'https://github.com/RaptorClash/pokevault/releases/download/v1.0.0/pokevault.zip',
            }
          ],
        }
      ];

      HttpOverrides.global = _MockHttpOverrides(responseBody: jsonEncode(fakeReleases));

      await tester.pumpWidget(buildApp(child: const DowngradeScreen(), isScreen: true));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Pokevault 1.0.0'), findsOneWidget);
      expect(find.text('Version v1.0.0'), findsOneWidget);

      // Tap on release
      await tester.tap(find.text('Pokevault 1.0.0'));
      await tester.pumpAndSettle();

      expect(find.byType(DowngradeDialog), findsOneWidget);

      HttpOverrides.global = null;
    });
  });

  group('TutorialSettingsScreen Tests', () {
    testWidgets('TutorialSettingsScreen renders chapters and handles reset all flow', (tester) async {
      when(() => mockTutorialProvider.isChapterCompleted(any())).thenReturn(true);
      when(() => mockTutorialProvider.resetAllTutorials()).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp(child: const TutorialSettingsScreen(), isScreen: true));
      await tester.pumpAndSettle();

      expect(find.text(t.tutorial_menu_title), findsOneWidget);
      expect(find.text(t.tutorial_replay_all), findsWidgets);

      // Tap Reset All button
      final resetBtn = find.text(t.tutorial_replay_all);
      await tester.tap(resetBtn.first);
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      final confirmBtn = find.text(t.reset);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      verify(() => mockTutorialProvider.resetAllTutorials()).called(1);
    });

    testWidgets('TutorialSettingsScreen opens ChapterDemoDialog when tapping replay', (tester) async {
      when(() => mockTutorialProvider.isChapterCompleted(any())).thenReturn(true);

      await tester.pumpWidget(buildApp(child: const TutorialSettingsScreen(), isScreen: true));
      await tester.pumpAndSettle();

      final replayButtons = find.text(t.tutorial_replay);
      expect(replayButtons, findsWidgets);

      await tester.tap(replayButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDemoDialog), findsOneWidget);
    });
  });

  group('CommunityCard, CreditsCard & SettingsHelper Tests', () {
    testWidgets('CommunityCard renders report issue and contribute items and launches URL', (tester) async {
      await tester.pumpWidget(buildApp(child: const CommunityCard()));
      await tester.pumpAndSettle();

      expect(find.text(t.report_issue_title), findsOneWidget);
      expect(find.text(t.contribute_title), findsOneWidget);

      await tester.tap(find.text(t.report_issue_title));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.contribute_title));
      await tester.pumpAndSettle();
    });

    testWidgets('CreditsCard renders credit items and handles taps', (tester) async {
      await tester.pumpWidget(buildApp(child: const CreditsCard()));
      await tester.pumpAndSettle();

      expect(find.text(t.credit_api_title), findsOneWidget);
      expect(find.text(t.credit_pokewiki_title), findsOneWidget);
      expect(find.text(t.credit_bisafans_title), findsOneWidget);

      await tester.tap(find.text(t.credit_api_title));
      await tester.pumpAndSettle();
    });

    testWidgets('SettingsHelper launchURL handles invalid url without crashing', (tester) async {
      await SettingsHelper.launchURL('invalid://url');
    });

    testWidgets('SettingsHelper buildSectionHeader renders title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SettingsHelper.buildSectionHeader(
                context,
                'Test Header',
                Icons.star,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Header'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
