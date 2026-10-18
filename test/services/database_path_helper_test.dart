import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokevault/services/database_path_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late Directory mockCurrentDir;
  late Directory mockDocumentsDir;
  late Directory mockSupportDir;
  late Directory mockExeDir;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('pokevault_path_test_');
    mockCurrentDir = Directory(p.join(tempRoot.path, 'project'))..createSync(recursive: true);
    mockDocumentsDir = Directory(p.join(tempRoot.path, 'documents'))..createSync(recursive: true);
    mockSupportDir = Directory(p.join(tempRoot.path, 'support'))..createSync(recursive: true);
    mockExeDir = Directory(p.join(tempRoot.path, 'release'))..createSync(recursive: true);

    DatabasePathHelper.overrideCurrentDirectory = mockCurrentDir;
    DatabasePathHelper.overrideDocumentsDirectory = mockDocumentsDir;
    DatabasePathHelper.overrideSupportDirectory = mockSupportDir;
    DatabasePathHelper.overrideIsDesktop = true;
    DatabasePathHelper.overrideExecutablePath = p.join(mockExeDir.path, 'pokevault.exe');
  });

  tearDown(() {
    DatabasePathHelper.resetOverrides();
    try {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DatabasePathHelper Path Resolution', () {
    test('Development mode: uses <current_dir>/database when pubspec.yaml exists', () async {
      File(p.join(mockCurrentDir.path, 'pubspec.yaml')).writeAsStringSync('name: pokevault\n');

      final dirPath = await DatabasePathHelper.resolveDatabaseDirectory();
      expect(dirPath, equals(p.join(mockCurrentDir.path, 'database')));

      final userDbPath = await DatabasePathHelper.resolveDatabasePath('user_data.sqlite');
      expect(userDbPath, equals(p.join(mockCurrentDir.path, 'database', 'user_data.sqlite')));

      final pokedexDbPath = await DatabasePathHelper.resolveDatabasePath('pokedex.sqlite');
      expect(pokedexDbPath, equals(p.join(mockCurrentDir.path, 'database', 'pokedex.sqlite')));
    });

    test('Portable / Release mode: uses <exe_dir>/database when no pubspec.yaml in current dir', () async {
      // Ensure no pubspec.yaml in mockCurrentDir
      final pubspec = File(p.join(mockCurrentDir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) pubspec.deleteSync();

      final dirPath = await DatabasePathHelper.resolveDatabaseDirectory();
      expect(dirPath, equals(p.join(mockExeDir.path, 'database')));

      final userDbPath = await DatabasePathHelper.resolveDatabasePath('user_data.sqlite');
      expect(userDbPath, equals(p.join(mockExeDir.path, 'database', 'user_data.sqlite')));
    });

    test('Read-only fallback: falls back to support directory if exe folder is read-only', () async {
      final pubspec = File(p.join(mockCurrentDir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) pubspec.deleteSync();

      DatabasePathHelper.overrideSimulateReadOnly = true;

      final dirPath = await DatabasePathHelper.resolveDatabaseDirectory();
      expect(dirPath, equals(p.join(mockSupportDir.path, 'database')));
    });
  });

  group('DatabasePathHelper Migration (Copy-Verify-Delete)', () {
    test('Migrates user_data.sqlite, WAL, SHM and pokedex.sqlite from Documents to target dir', () async {
      File(p.join(mockCurrentDir.path, 'pubspec.yaml')).writeAsStringSync('name: pokevault\n');

      // Create legacy database files in Documents
      final docUserDb = File(p.join(mockDocumentsDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('LEGACY_USER_DATA_CONTENT');
      final docUserWal = File(p.join(mockDocumentsDir.path, 'user_data.sqlite-wal'))
        ..writeAsStringSync('LEGACY_WAL_CONTENT');
      final docUserShm = File(p.join(mockDocumentsDir.path, 'user_data.sqlite-shm'))
        ..writeAsStringSync('LEGACY_SHM_CONTENT');
      final docPokedexDb = File(p.join(mockDocumentsDir.path, 'pokedex.sqlite'))
        ..writeAsStringSync('LEGACY_POKEDEX_CONTENT');

      await DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();

      final targetDatabaseDir = p.join(mockCurrentDir.path, 'database');
      final targetUserDb = File(p.join(targetDatabaseDir, 'user_data.sqlite'));
      final targetUserWal = File(p.join(targetDatabaseDir, 'user_data.sqlite-wal'));
      final targetUserShm = File(p.join(targetDatabaseDir, 'user_data.sqlite-shm'));
      final targetPokedexDb = File(p.join(targetDatabaseDir, 'pokedex.sqlite'));

      // 1. Files exist in target folder with correct contents
      expect(targetUserDb.existsSync(), isTrue);
      expect(targetUserDb.readAsStringSync(), equals('LEGACY_USER_DATA_CONTENT'));

      expect(targetUserWal.existsSync(), isTrue);
      expect(targetUserWal.readAsStringSync(), equals('LEGACY_WAL_CONTENT'));

      expect(targetUserShm.existsSync(), isTrue);
      expect(targetUserShm.readAsStringSync(), equals('LEGACY_SHM_CONTENT'));

      expect(targetPokedexDb.existsSync(), isTrue);
      expect(targetPokedexDb.readAsStringSync(), equals('LEGACY_POKEDEX_CONTENT'));

      // 2. Documents directory has been cleaned up completely
      expect(docUserDb.existsSync(), isFalse);
      expect(docUserWal.existsSync(), isFalse);
      expect(docUserShm.existsSync(), isFalse);
      expect(docPokedexDb.existsSync(), isFalse);
    });

    test('Handles conflict when target already exists and creates backup if Documents copy is newer', () async {
      File(p.join(mockCurrentDir.path, 'pubspec.yaml')).writeAsStringSync('name: pokevault\n');
      final targetDatabaseDir = Directory(p.join(mockCurrentDir.path, 'database'))..createSync(recursive: true);

      // Target file created in the past
      final targetUserDb = File(p.join(targetDatabaseDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('OLD_TARGET_CONTENT');
      targetUserDb.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 5)));

      // Documents file created more recently
      final docUserDb = File(p.join(mockDocumentsDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('NEWER_DOCUMENTS_CONTENT');
      docUserDb.setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 5)));

      await DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();

      // Documents file should have replaced target because it was newer, and backed up old target
      expect(targetUserDb.readAsStringSync(), equals('NEWER_DOCUMENTS_CONTENT'));
      expect(docUserDb.existsSync(), isFalse);

      // Check that a backup file exists in targetDatabaseDir
      final backups = targetDatabaseDir
          .listSync()
          .where((f) => p.basename(f.path).startsWith('user_data.sqlite.bak_'))
          .toList();
      expect(backups.isNotEmpty, isTrue);
    });

    test('Cleans up older Documents file without overwriting newer target database', () async {
      File(p.join(mockCurrentDir.path, 'pubspec.yaml')).writeAsStringSync('name: pokevault\n');
      final targetDatabaseDir = Directory(p.join(mockCurrentDir.path, 'database'))..createSync(recursive: true);

      // Target file is newer
      final targetUserDb = File(p.join(targetDatabaseDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('NEW_TARGET_CONTENT');
      targetUserDb.setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 5)));

      // Documents file is older
      final docUserDb = File(p.join(mockDocumentsDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('OLD_DOCUMENTS_CONTENT');
      docUserDb.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 5)));

      await DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();

      // Target remains untouched
      expect(targetUserDb.readAsStringSync(), equals('NEW_TARGET_CONTENT'));
      // Documents file cleaned up
      expect(docUserDb.existsSync(), isFalse);
    });

    test('Conflict handling with WAL/SHM: backs up target WAL and copies newer Documents WAL', () async {
      File(p.join(mockCurrentDir.path, 'pubspec.yaml')).writeAsStringSync('name: pokevault\n');
      final targetDatabaseDir = Directory(p.join(mockCurrentDir.path, 'database'))..createSync(recursive: true);

      // Target older files
      final targetUserDb = File(p.join(targetDatabaseDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('OLD_TARGET_DB');
      final targetUserWal = File(p.join(targetDatabaseDir.path, 'user_data.sqlite-wal'))
        ..writeAsStringSync('OLD_TARGET_WAL');
      final oldTime = DateTime.now().subtract(const Duration(hours: 3));
      targetUserDb.setLastModifiedSync(oldTime);
      targetUserWal.setLastModifiedSync(oldTime);

      // Documents newer files
      final docUserDb = File(p.join(mockDocumentsDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('NEWER_DOC_DB');
      final docUserWal = File(p.join(mockDocumentsDir.path, 'user_data.sqlite-wal'))
        ..writeAsStringSync('NEWER_DOC_WAL');
      final newTime = DateTime.now().subtract(const Duration(minutes: 5));
      docUserDb.setLastModifiedSync(newTime);
      docUserWal.setLastModifiedSync(newTime);

      await DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();

      // Target DB and WAL must contain newer Documents content
      expect(targetUserDb.readAsStringSync(), equals('NEWER_DOC_DB'));
      expect(targetUserWal.readAsStringSync(), equals('NEWER_DOC_WAL'));

      // Both target DB and target WAL backups must exist
      final dbBackups = targetDatabaseDir
          .listSync()
          .where((f) => p.basename(f.path).startsWith('user_data.sqlite.bak_'))
          .toList();
      final walBackups = targetDatabaseDir
          .listSync()
          .where((f) => p.basename(f.path).startsWith('user_data.sqlite-wal.bak_'))
          .toList();
      expect(dbBackups.isNotEmpty, isTrue);
      expect(walBackups.isNotEmpty, isTrue);

      // Documents files must be deleted
      expect(docUserDb.existsSync(), isFalse);
      expect(docUserWal.existsSync(), isFalse);
    });

    test('Conflict handling with WAL: newer target does NOT inherit old Documents WAL', () async {
      File(p.join(mockCurrentDir.path, 'pubspec.yaml')).writeAsStringSync('name: pokevault\n');
      final targetDatabaseDir = Directory(p.join(mockCurrentDir.path, 'database'))..createSync(recursive: true);

      // Target newer DB without WAL
      final targetUserDb = File(p.join(targetDatabaseDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('NEWER_TARGET_DB');
      targetUserDb.setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 5)));

      // Documents older DB with WAL
      final docUserDb = File(p.join(mockDocumentsDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('OLDER_DOC_DB');
      final docUserWal = File(p.join(mockDocumentsDir.path, 'user_data.sqlite-wal'))
        ..writeAsStringSync('OLDER_DOC_WAL');
      final oldTime = DateTime.now().subtract(const Duration(hours: 3));
      docUserDb.setLastModifiedSync(oldTime);
      docUserWal.setLastModifiedSync(oldTime);

      await DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();

      // Target must NOT have received the older WAL from Documents!
      final targetWal = File(p.join(targetDatabaseDir.path, 'user_data.sqlite-wal'));
      expect(targetWal.existsSync(), isFalse, reason: 'Old Documents WAL must never be copied to newer target DB');

      // Documents files must be deleted
      expect(docUserDb.existsSync(), isFalse);
      expect(docUserWal.existsSync(), isFalse);
    });

    test('Mobile migration: migrates Documents DBs to Support directory when on mobile', () async {
      DatabasePathHelper.overrideIsDesktop = false;

      final docUserDb = File(p.join(mockDocumentsDir.path, 'user_data.sqlite'))
        ..writeAsStringSync('MOBILE_USER_DATA');
      final docPokedexDb = File(p.join(mockDocumentsDir.path, 'pokedex.sqlite'))
        ..writeAsStringSync('MOBILE_POKEDEX_DATA');

      await DatabasePathHelper.migrateLegacyDocumentsDatabasesIfNeeded();

      final mobileTargetDir = p.join(mockSupportDir.path, 'database');
      final targetUserDb = File(p.join(mobileTargetDir, 'user_data.sqlite'));
      final targetPokedexDb = File(p.join(mobileTargetDir, 'pokedex.sqlite'));

      expect(targetUserDb.existsSync(), isTrue);
      expect(targetUserDb.readAsStringSync(), equals('MOBILE_USER_DATA'));
      expect(targetPokedexDb.existsSync(), isTrue);
      expect(targetPokedexDb.readAsStringSync(), equals('MOBILE_POKEDEX_DATA'));

      expect(docUserDb.existsSync(), isFalse);
      expect(docPokedexDb.existsSync(), isFalse);
    });
  });
}
