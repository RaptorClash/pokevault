import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/dex_storage_service.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  bool returnNullForDownloads;
  MockPathProviderPlatform(this.tempDir, {this.returnNullForDownloads = false});

  @override
  Future<String?> getDownloadsPath() async => returnNullForDownloads ? null : tempDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

class MockFileSelectorPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FileSelectorPlatform {
  XFile? mockFileToReturn;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    return mockFileToReturn;
  }
}

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockPathProviderPlatform mockPathProvider;
  late MockFileSelectorPlatform mockFileSelector;
  late MockDexProvider mockDexProvider;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pokevault_storage_test_');
    mockPathProvider = MockPathProviderPlatform(tempDir);
    PathProviderPlatform.instance = mockPathProvider;

    mockFileSelector = MockFileSelectorPlatform();
    FileSelectorPlatform.instance = mockFileSelector;

    mockDexProvider = MockDexProvider();
    when(() => mockDexProvider.folders).thenReturn([]);
    when(() => mockDexProvider.structure).thenReturn({'root': []});
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DexStorageService Tests', () {
    test('exportDexes creates a valid JSON backup file on Desktop with dexes, folders and structure', () async {
      final dex1 = UserDex(
        id: 'export_dex_1',
        title: 'Export Dex 1',
        region: 'kanto',
        includeGenders: false,
        includeRegional: true,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: ['1', '2'],
        customBoxes: [
          CustomBoxState(title: 'Box Alpha', pokemonIds: ['1']),
        ],
      );

      final dexFolder = DexFolder(id: 'folder_1', title: 'My Folder');
      when(() => mockDexProvider.folders).thenReturn([dexFolder]);
      when(() => mockDexProvider.structure).thenReturn({
        'root': ['export_dex_1'],
        'folder_1': [],
      });

      await DexStorageService.exportDexes([dex1], mockDexProvider);

      // Verify a backup file was written in tempDir
      final files = tempDir.listSync().whereType<File>().toList();
      expect(files, isNotEmpty);

      final backupFile = files.firstWhere((f) => f.path.contains('pokevault_backup_'));
      expect(backupFile.existsSync(), isTrue);

      final content = backupFile.readAsStringSync();
      final Map<String, dynamic> parsed = jsonDecode(content);

      expect(parsed.containsKey('dexes'), isTrue);
      expect(parsed.containsKey('folders'), isTrue);
      expect(parsed.containsKey('structure'), isTrue);

      final dexesList = parsed['dexes'] as List;
      expect(dexesList.length, equals(1));
      expect(dexesList.first['id'], equals('export_dex_1'));
      expect(dexesList.first['title'], equals('Export Dex 1'));
      expect(dexesList.first['caughtIds'], equals(['1', '2']));

      final foldersList = parsed['folders'] as List;
      expect(foldersList.length, equals(1));
      expect(foldersList.first['id'], equals('folder_1'));

      final structureMap = parsed['structure'] as Map<String, dynamic>;
      expect(structureMap['root'], equals(['export_dex_1']));
    });

    test('importDexes returns null when file selection is canceled', () async {
      mockFileSelector.mockFileToReturn = null;

      final result = await DexStorageService.importDexes(mockDexProvider);
      expect(result, isNull);
    });

    test('importDexes parses and returns decoded JSON map when file is picked', () async {
      final sampleBackup = {
        'dexes': [
          {
            'id': 'imported_dex',
            'title': 'Imported Title',
            'region': 'johto',
            'caught_ids': ['152'],
          }
        ],
        'folders': [],
        'structure': {'root': ['imported_dex']},
      };

      final testFile = File('${tempDir.path}/test_import.json');
      testFile.writeAsStringSync(jsonEncode(sampleBackup));

      mockFileSelector.mockFileToReturn = XFile(testFile.path);

      final result = await DexStorageService.importDexes(mockDexProvider);

      expect(result, isNotNull);
      expect(result is Map<String, dynamic>, isTrue);
      expect(result!['dexes'][0]['id'], equals('imported_dex'));
      expect(result['dexes'][0]['title'], equals('Imported Title'));
      expect(result['structure']['root'], equals(['imported_dex']));
    });

    test('importDexes returns null and catches error when file contains invalid JSON', () async {
      final invalidFile = File('${tempDir.path}/invalid.json');
      invalidFile.writeAsStringSync('NOT_A_VALID_JSON{:::');

      mockFileSelector.mockFileToReturn = XFile(invalidFile.path);

      final result = await DexStorageService.importDexes(mockDexProvider);
      expect(result, isNull);
    });

    test('importDexes returns null when file contains a JSON array instead of a JSON map', () async {
      final arrayFile = File('${tempDir.path}/array.json');
      arrayFile.writeAsStringSync('[1, 2, 3]');

      mockFileSelector.mockFileToReturn = XFile(arrayFile.path);

      final result = await DexStorageService.importDexes(mockDexProvider);
      expect(result, isNull);
    });

    test('exportDexes falls back to application documents directory if getDownloadsDirectory returns null', () async {
      mockPathProvider.returnNullForDownloads = true;

      final dex = UserDex(
        id: 'fallback_dex',
        title: 'Fallback Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        caughtIds: [],
        customBoxes: [],
      );

      await DexStorageService.exportDexes([dex], mockDexProvider);

      final files = tempDir.listSync().whereType<File>().toList();
      final backup = files.firstWhere((f) => f.path.contains('pokevault_backup_'));
      expect(backup.existsSync(), isTrue);
    });
  });
}
