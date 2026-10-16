import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/screens/abilities/abilities_dex_screen.dart';
import 'package:pokevault/screens/abilities/ability_detail_screen.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getLibraryPath() async => tempDir.path;

  @override
  Future<String?> getDownloadsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('pokevault_abilities_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    await DatabaseService.instance.appDatabase;
    await DatabaseService.instance.userDatabase;
  });

  tearDownAll(() async {
    final appDb = await DatabaseService.instance.appDatabase;
    await appDb.close();
    final userDb = await DatabaseService.instance.userDatabase;
    await userDb.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();

    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');
    when(() => mockDexProvider.allPokemon).thenReturn([]);
    when(() => mockDexProvider.ballUrls).thenReturn({});
  });

  Future<void> waitForAbilitiesLoaded(WidgetTester tester) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        return;
      }
    }
    throw TimeoutException('Timed out waiting for AbilitiesDexScreen to load');
  }

  group('AbilitiesDexScreen Widget Tests', () {
    testWidgets('Renders ability list, progress counter, and search bar', (tester) async {
      final dex = createTestUserDex(
        id: 'abilities_dex_1',
        caughtIds: ['ability_1'],
        viewMode: 'list',
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: AbilitiesDexScreen(dex: dex),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForAbilitiesLoaded(tester);

      // Check title and caught count
      expect(find.text('Fähigkeiten-Dex'), findsOneWidget);
      expect(find.textContaining('1 /'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Check that abilities are loaded
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('Search query filters ability list', (tester) async {
      final dex = createTestUserDex(
        id: 'abilities_dex_search',
        viewMode: 'list',
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: AbilitiesDexScreen(dex: dex),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForAbilitiesLoaded(tester);

      // Search for specific ability (e.g. 'Notdünger')
      await tester.enterText(find.byType(TextField), 'Notdünger');
      await tester.pump();

      expect(find.widgetWithText(ListTile, 'Notdünger'), findsOneWidget);

      // Search for something non-existent
      await tester.enterText(find.byType(TextField), 'XYZNonExistentAbility');
      await tester.pump();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Toggle view mode switches between list and grid views', (tester) async {
      final dex = createTestUserDex(
        id: 'abilities_dex_toggle',
        viewMode: 'list',
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: AbilitiesDexScreen(dex: dex),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForAbilitiesLoaded(tester);

      // Initially in list mode
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      // Tap toggle view mode action button
      await tester.tap(find.byTooltip('Ansicht wechseln'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();

      // Now in grid mode
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Tapping caught icon toggles registered status', (tester) async {
      final dex = createTestUserDex(
        id: 'abilities_dex_caught',
        caughtIds: [],
        viewMode: 'list',
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: AbilitiesDexScreen(dex: dex),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForAbilitiesLoaded(tester);

      expect(find.textContaining('0 /'), findsOneWidget);

      // Tap first ability's circle icon
      final firstCheck = find.byIcon(Icons.circle_outlined).first;
      await tester.tap(firstCheck);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();

      // Counter should now show 1 /
      expect(find.textContaining('1 /'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('Tapping caught icon in grid view mode toggles registered status', (tester) async {
      final dex = createTestUserDex(
        id: 'abilities_grid_caught',
        caughtIds: [],
        viewMode: 'grid',
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: AbilitiesDexScreen(dex: dex),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForAbilitiesLoaded(tester);

      expect(find.byType(GridView), findsOneWidget);
      expect(find.textContaining('0 /'), findsOneWidget);

      final firstCircle = find.byIcon(Icons.circle_outlined).first;
      await tester.tap(firstCircle);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 25));
      });
      await tester.pump();

      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('Long press on ability navigates to AbilityDetailScreen', (tester) async {
      final dex = createTestUserDex(
        id: 'abilities_dex_nav',
        viewMode: 'list',
      );

      await tester.pumpWidget(
        wrapWithApp(
          child: AbilitiesDexScreen(dex: dex),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForAbilitiesLoaded(tester);

      // Long press first ability list item
      await tester.longPress(find.byType(ListTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AbilityDetailScreen), findsOneWidget);
    });
  });
}
