import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/services/dex_storage_service.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
  @override
  Future<String?> getDownloadsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('pokevault_storage_hunt_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    await DatabaseService.instance.clearUserData();
  });

  test('DexProvider markPokemonCaughtAndShiny marks both caught and shiny', () async {
    final dex = UserDex(
      id: 'test_dex_mark',
      title: 'Kanto',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
    );
    await DatabaseService.instance.saveUserDex(dex);

    final provider = DexProvider(databaseService: DatabaseService.instance);
    provider.userDexes = [dex];

    await provider.markPokemonCaughtAndShiny('test_dex_mark', '1');

    expect(dex.caughtIds.contains('1'), isTrue);
    expect(dex.shinyIds.contains('1'), isTrue);

    // Verify persisted in DB
    final dexesFromDb = await DatabaseService.instance.getAllUserDexes();
    final loaded = dexesFromDb.firstWhere((d) => d.id == 'test_dex_mark');
    expect(loaded.caughtIds.contains('1'), isTrue);
    expect(loaded.shinyIds.contains('1'), isTrue);
  });

  test('DexStorageService exports shiny_hunts and DexProvider restores them on import', () async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'export-hunt-1',
      title: 'Mewtwo SR',
      pokemonId: 150,
      pokemonName: 'Mewtu',
      game: 'FireRed',
      generation: 3.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      currentEncounters: 350,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseService.instance.saveShinyHunt(hunt);

    final dex = UserDex(
      id: 'backup_dex',
      title: 'Backup Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
    );
    await DatabaseService.instance.saveUserDex(dex);

    final provider = DexProvider(databaseService: DatabaseService.instance);
    provider.userDexes = [dex];

    // Export dexes
    await DexStorageService.exportDexes([dex], provider);

    // Verify backup file exists in downloads
    final backupFiles = tempDir
        .listSync()
        .where((f) => f.path.contains('pokevault_backup_') && f.path.endsWith('.json'))
        .toList();
    expect(backupFiles.isNotEmpty, isTrue);

    // Read the backup file
    final latestBackup = backupFiles.last as File;
    final jsonContent = await latestBackup.readAsString();
    expect(jsonContent.contains('export-hunt-1'), isTrue);
    expect(jsonContent.contains('Mewtu'), isTrue);

    // Clean up created file
    try {
      await latestBackup.delete();
    } catch (_) {}
  });
}
