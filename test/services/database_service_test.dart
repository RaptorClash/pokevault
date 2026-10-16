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

  test('Test saveUserDex', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();

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

    print('Calling saveUserDex...');
    await DatabaseService.instance.saveUserDex(dex);
    print('saveUserDex succeeded!');

    final dexes = await DatabaseService.instance.getAllUserDexes();
    print('getAllUserDexes returned ${dexes.length} dexes');
    final loaded = dexes.firstWhere((d) => d.id == 'test_dex_persist');
    expect(loaded.customBoxes.first.autoShift, isFalse);
    expect(loaded.customBoxes.first.strictLimits, isFalse);
    expect(loaded.customBoxes.first.patternAutoCreate, isTrue);
    expect(loaded.customBoxes.first.autoDeleteEmpty, isFalse);
    print('All assertions passed!');
  });
}
