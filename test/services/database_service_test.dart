import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('Test saveUserDex persists custom box behavioral flags', () async {
    final dex = UserDex(
      id: 'test_dex_persist',
      title: 'Persist Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      customBoxes: [
        CustomBoxState(
          title: 'Box 1',
          pokemonIds: ['1'],
          autoShift: false,
          strictLimits: false,
          patternAutoCreate: true,
          autoDeleteEmpty: false,
        ),
      ],
    );

    await DatabaseService.instance.saveUserDex(dex);

    final dexes = await DatabaseService.instance.getAllUserDexes();
    final loaded = dexes.firstWhere((d) => d.id == 'test_dex_persist');
    expect(loaded.customBoxes.first.autoShift, isFalse);
    expect(loaded.customBoxes.first.strictLimits, isFalse);
    expect(loaded.customBoxes.first.patternAutoCreate, isTrue);
    expect(loaded.customBoxes.first.autoDeleteEmpty, isFalse);
  });

  test('cleanupOrphanedPokemon removes unreferenced instance records', () async {
    const dexId = 'test_cleanup_dex';

    // Insert test status rows directly or via savePokemonStatus
    await DatabaseService.instance.savePokemonStatus(dexId, '1', isCaught: true);
    await DatabaseService.instance.savePokemonStatus(dexId, '1__dup1', isCaught: true);
    await DatabaseService.instance.savePokemonStatus(dexId, '1__dup2', isCaught: true);
    await DatabaseService.instance.savePokemonStatus(dexId, '2__dup1', isCaught: true);

    // Active unique IDs contains '1__dup1', while '1__dup2' and '2__dup1' are orphaned
    final activeIds = {'1', '1__dup1'};
    final deleted = await DatabaseService.instance.cleanupOrphanedPokemon(dexId, activeIds);
    expect(deleted, equals(2));

    final db = await DatabaseService.instance.userDatabase;
    final remaining = await db.query(
      'user_pokemon',
      columns: ['unique_id'],
      where: 'dex_id = ?',
      whereArgs: [dexId],
    );
    final remainingIds = remaining.map((r) => r['unique_id'] as String).toSet();

    expect(remainingIds.contains('1'), isTrue, reason: 'Base Pokémon without __ is preserved');
    expect(remainingIds.contains('1__dup1'), isTrue, reason: 'Active duplicate is preserved');
    expect(remainingIds.contains('1__dup2'), isFalse, reason: 'Orphaned duplicate is deleted');
    expect(remainingIds.contains('2__dup1'), isFalse, reason: 'Orphaned duplicate is deleted');
  });
}
