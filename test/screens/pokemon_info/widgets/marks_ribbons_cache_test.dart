import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/marks_widget.dart';
import 'package:pokevault/screens/pokemon_info/widgets/ribbons_widget.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/widgets/universal_poke_image.dart';

class MockDexProvider extends Mock implements DexProvider {}

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getLibraryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getDownloadsPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
  });

  final testPokemon = Pokemon(
    id: 25,
    nameDe: 'Pikachu',
    nameEn: 'Pikachu',
    hasGenderDifferences: true,
    genderRate: 4,
    captureRate: 190,
    evolutionChainId: 10,
    eggGroups: ['Field', 'Fairy'],
    weight: 6.0,
    speed: 90,
    forms: [],
  );

  final testEntry = DexDisplayEntry(
    pokemon: testPokemon,
    uniqueId: '25',
    displaySuffix: '',
    imageUrl: 'https://example.com/25.png',
  );

  testWidgets(
      'MarksWidget and RibbonsWidget constrain UniversalPokeImage grid thumbnails to prevent memory bloat',
      (tester) async {
    final mockDexProvider = MockDexProvider();
    when(() => mockDexProvider.userDexes).thenReturn([
      UserDex.fallback('kanto'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DexProvider>.value(
            value: mockDexProvider,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  MarksWidget(
                    entry: testEntry,
                    dexId: 'kanto',
                    marksKey: GlobalKey(),
                  ),
                  RibbonsWidget(
                    entry: testEntry,
                    dexId: 'kanto',
                    ribbonsKey: GlobalKey(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Pump async DB operations for ribbon/mark loading
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
        break;
      }
    }

    final images = tester
        .widgetList<UniversalPokeImage>(find.byType(UniversalPokeImage))
        .toList();

    for (final img in images) {
      // Every rendered mark/ribbon must have explicit width & height <= 48 to avoid 400x400 decoding
      expect(img.width, isNotNull);
      expect(img.height, isNotNull);
      expect(img.width!, lessThanOrEqualTo(48.0));
      expect(img.height!, lessThanOrEqualTo(48.0));
    }
  });
}
