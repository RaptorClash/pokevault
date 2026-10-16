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
import 'package:pokevault/screens/dex/route_tracker_screen.dart';
import 'package:pokevault/l10n/app_translations.dart';
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

    tempDir = Directory.systemTemp.createTempSync('pokevault_routes_test_');
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
    when(() => mockDexProvider.togglePokemon(any(), any())).thenAnswer((_) async {});
  });

  Future<void> waitForRoutesLoaded(WidgetTester tester) async {
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
    throw TimeoutException('Timed out waiting for RouteTrackerScreen to load');
  }

  group('RouteTrackerScreen Widget Tests', () {
    testWidgets('Renders route tracker with search bar and routes from database', (tester) async {
      final poke = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: poke, uniqueId: '25');
      final dex = createTestUserDex(id: 'dex_routes', region: 'kanto');

      await tester.pumpWidget(
        wrapWithApp(
          child: RouteTrackerScreen(
            liveDex: dex,
            displayEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForRoutesLoaded(tester);

      // Check header and search bar
      expect(find.byType(TextField), findsOneWidget);
      // Viridian Forest should be in Kanto encounters for Pikachu
      expect(find.text('Viridian Forest'), findsOneWidget);
    });

    testWidgets('Expanding route reveals Pokemon entries and allows toggling caught status', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final poke = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: poke, uniqueId: '25');
      final dex = createTestUserDex(id: 'dex_expand', region: 'kanto');

      await tester.pumpWidget(
        wrapWithApp(
          child: RouteTrackerScreen(
            liveDex: dex,
            displayEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForRoutesLoaded(tester);

      // Tap on Viridian Forest expansion tile
      await tester.tap(find.text('Viridian Forest'));
      await tester.pumpAndSettle();

      // Pikachu should now be visible inside the expanded tile
      expect(find.text('Pikachu'), findsWidgets);
      expect(find.text('#025'), findsWidgets);

      // Tap the catching pokeball icon
      final pokeballBtn = find.widgetWithIcon(IconButton, Icons.catching_pokemon).first;
      await tester.ensureVisible(pokeballBtn);
      await tester.tap(pokeballBtn);
      await tester.pump();

      verify(() => mockDexProvider.togglePokemon(dex.id, '25')).called(1);
    });

    testWidgets('Search query filters routes by name', (tester) async {
      final poke = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: poke, uniqueId: '25');
      final dex = createTestUserDex(id: 'dex_filter', region: 'kanto');

      await tester.pumpWidget(
        wrapWithApp(
          child: RouteTrackerScreen(
            liveDex: dex,
            displayEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForRoutesLoaded(tester);

      expect(find.text('Viridian Forest'), findsOneWidget);

      // Search for Power Plant
      await tester.enterText(find.byType(TextField), 'Power Plant');
      await tester.pump();

      expect(find.widgetWithText(Card, 'Power Plant'), findsOneWidget);
      expect(find.widgetWithText(Card, 'Viridian Forest'), findsNothing);

      // Search for non-existent route
      await tester.enterText(find.byType(TextField), 'AtlantisNonExistent');
      await tester.pump();

      expect(find.text(Translator.get('no_encounters_found')), findsOneWidget);
    });

    testWidgets('Empty state message when no encounters match', (tester) async {
      final dex = createTestUserDex(id: 'dex_empty_routes', region: 'kanto');

      await tester.pumpWidget(
        wrapWithApp(
          child: RouteTrackerScreen(
            liveDex: dex,
            displayEntries: const [],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForRoutesLoaded(tester);

      expect(find.text(Translator.get('no_encounters_found')), findsOneWidget);
    });

    testWidgets('Toggling hideCompleted switch hides routes whose pokemon are all caught', (tester) async {
      final poke = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: poke, uniqueId: '25');
      // Mark 25 as caught
      final dex = createTestUserDex(id: 'dex_hide_completed', region: 'kanto', caughtIds: ['25']);

      await tester.pumpWidget(
        wrapWithApp(
          child: RouteTrackerScreen(
            liveDex: dex,
            displayEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForRoutesLoaded(tester);

      expect(find.text('Viridian Forest'), findsOneWidget);

      // Toggle switch "Fertige Routen ausblenden"
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Since Pikachu is caught, Viridian Forest should now be hidden
      expect(find.text('Viridian Forest'), findsNothing);
      expect(find.text(Translator.get('no_encounters_found')), findsOneWidget);
    });

    testWidgets('Games filter expansion allows clearing selected games', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final poke = createTestPokemon(id: 25, nameDe: 'Pikachu', nameEn: 'Pikachu');
      final entry = createTestEntry(pokemon: poke, uniqueId: '25');
      final dex = createTestUserDex(id: 'dex_games_filter', region: 'kanto');

      await tester.pumpWidget(
        wrapWithApp(
          child: RouteTrackerScreen(
            liveDex: dex,
            displayEntries: [entry],
          ),
          mockDexProvider: mockDexProvider,
          mockSettingsProvider: mockSettingsProvider,
          language: 'de',
        ),
      );
      await waitForRoutesLoaded(tester);

      expect(find.text('Viridian Forest'), findsOneWidget);

      // Expand games filter
      await tester.tap(find.text(Translator.get('games_filter_title')));
      await tester.pumpAndSettle();

      // Tap 'Keine' button
      await tester.tap(find.widgetWithText(TextButton, Translator.get('none')));
      await tester.pumpAndSettle();

      // All routes should disappear
      expect(find.text('Viridian Forest'), findsNothing);
      expect(find.text(Translator.get('no_encounters_found')), findsOneWidget);
    });
  });
}
