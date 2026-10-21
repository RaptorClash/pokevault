import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({'app_db_version': 27});
  });

  setUp(() {
    DatabaseService.instance.clearMemoryCache();
  });

  tearDown(() {
    DatabaseService.instance.clearMemoryCache();
  });

  group('DatabaseService In-Memory Cache Quality Gate Tests', () {
    test('getAllRibbons returns identical in-memory instance on subsequent calls', () async {
      final ribbons1 = await DatabaseService.instance.getAllRibbons();
      final ribbons2 = await DatabaseService.instance.getAllRibbons();

      // Caching check: Reference identity proves zero re-querying from SQLite
      expect(identical(ribbons1, ribbons2), isTrue,
          reason: 'Subsequent calls to getAllRibbons must return the cached instance');

      // Invalidation check
      DatabaseService.instance.clearMemoryCache();
      final ribbons3 = await DatabaseService.instance.getAllRibbons();
      expect(identical(ribbons1, ribbons3), isFalse,
          reason: 'After clearMemoryCache, a fresh instance must be loaded');
      expect(ribbons3.length, equals(ribbons1.length));
    });

    test('getAvailableVersionGroups caches results by pokemonId', () async {
      final groups1 = await DatabaseService.instance.getAvailableVersionGroups(1);
      final groups2 = await DatabaseService.instance.getAvailableVersionGroups(1);

      expect(identical(groups1, groups2), isTrue,
          reason: 'Subsequent calls for the same pokemonId must return cached list');

      DatabaseService.instance.clearMemoryCache();
      final groups3 = await DatabaseService.instance.getAvailableVersionGroups(1);
      expect(identical(groups1, groups3), isFalse);
      expect(groups3, equals(groups1));
    });

    test('getEvolutionChain caches results by chainId', () async {
      final chain1 = await DatabaseService.instance.getEvolutionChain(1);
      final chain2 = await DatabaseService.instance.getEvolutionChain(1);

      if (chain1 != null) {
        expect(identical(chain1, chain2), isTrue,
            reason: 'Evolution chain data must be cached in memory');
      }

      DatabaseService.instance.clearMemoryCache();
      final chain3 = await DatabaseService.instance.getEvolutionChain(1);
      if (chain1 != null) {
        expect(identical(chain1, chain3), isFalse);
      }
    });

    test('getMatchingBalls caches results by uniqueId', () async {
      final balls1 = await DatabaseService.instance.getMatchingBalls('1');
      final balls2 = await DatabaseService.instance.getMatchingBalls('1');

      if (balls1 != null) {
        expect(identical(balls1, balls2), isTrue,
            reason: 'Matching balls must be cached in memory');
      }

      DatabaseService.instance.clearMemoryCache();
      final balls3 = await DatabaseService.instance.getMatchingBalls('1');
      if (balls1 != null) {
        expect(identical(balls1, balls3), isFalse);
      }
    });

    test('getEncounters caches results by pokemonId', () async {
      final enc1 = await DatabaseService.instance.getEncounters(1);
      final enc2 = await DatabaseService.instance.getEncounters(1);

      if (enc1 != null) {
        expect(identical(enc1, enc2), isTrue,
            reason: 'Encounters must be cached in memory');
      }

      DatabaseService.instance.clearMemoryCache();
      final enc3 = await DatabaseService.instance.getEncounters(1);
      if (enc1 != null) {
        expect(identical(enc1, enc3), isFalse);
      }
    });

    test('Cache behaves robustly when querying non-existent IDs', () async {
      final nonExistentChain1 = await DatabaseService.instance.getEvolutionChain(-1);
      final nonExistentChain2 = await DatabaseService.instance.getEvolutionChain(-1);
      expect(nonExistentChain1, isNull);
      expect(nonExistentChain2, isNull);

      final nonExistentEnc1 = await DatabaseService.instance.getEncounters(999999);
      final nonExistentEnc2 = await DatabaseService.instance.getEncounters(999999);
      expect(nonExistentEnc1, isNull);
      expect(nonExistentEnc2, isNull);
    });
  });
}
