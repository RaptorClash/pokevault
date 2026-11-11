import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': DatabaseService.currentAppDbVersion});
  });

  tearDownAll(() {
    HttpOverrides.global = null;
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

    // Pump async DB operations until both widgets finish loading
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (find.byType(ExpansionTile).evaluate().length >= 2) {
        break;
      }
    }

    // Let any scheduled layout updates settle
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

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

    // Cleanly unmount and drain timers to prevent pending timer asserts in CI
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
