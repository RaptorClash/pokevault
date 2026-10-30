import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helper for resolving portable SQLite database paths and migrating legacy locations.
///
/// Ensures database files (`user_data.sqlite` and `pokedex.sqlite`) are stored
/// in a portable directory adjacent to the executable or project workspace,
/// rather than polluting the user's system Documents directory.
///
/// Path resolution rules:
/// * **Web**: Returns empty string (in-memory or IndexedDB handled via FFI Web).
/// * **Development (Desktop)**: `<project_root>/database` if `pubspec.yaml` is present.
/// * **Release / Portable (Desktop)**: `<exe_dir>/database` next to the executable.
/// * **Read-Only Fallback**: `<app_support_dir>/database` if target directory lacks write permission.
/// * **Mobile (Android/iOS)**: `<app_support_dir>/database`.
class DatabasePathHelper {
  /// Test override for simulating a specific working directory.
  @visibleForTesting
  static Directory? overrideCurrentDirectory;

  @visibleForTesting
  static Directory? overrideDocumentsDirectory;

  @visibleForTesting
  static Directory? overrideSupportDirectory;

  @visibleForTesting
  static bool? overrideIsDesktop;

  @visibleForTesting
  static String? overrideExecutablePath;

  @visibleForTesting
  static bool? overrideSimulateReadOnly;

  @visibleForTesting
  static void resetOverrides() {
    overrideCurrentDirectory = null;
    overrideDocumentsDirectory = null;
    overrideSupportDirectory = null;
    overrideIsDesktop = null;
    overrideExecutablePath = null;
    overrideSimulateReadOnly = null;
  }

  static bool get _isDesktop {
    if (overrideIsDesktop != null) return overrideIsDesktop!;
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// Resolves the portable database directory path for the current platform.
  ///
  /// Verifies directory existence and write permissions via a probe file before returning.
  /// Falls back to application support directory if the primary location is read-only.
  static Future<String> resolveDatabaseDirectory() async {
    if (kIsWeb) return '';

    if (_isDesktop) {
      if (overrideCurrentDirectory == null &&
          (Platform.environment.containsKey('FLUTTER_TEST') ||
           Platform.environment.containsKey('DART_TEST') ||
           Platform.script.path.contains('test'))) {
        final testDir = Directory(p.join(Directory.systemTemp.path, 'pokevault_test_dbs'));
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        return testDir.path;
      }

      final currentDir = overrideCurrentDirectory ?? Directory.current;
      final pubspecFile = File(p.join(currentDir.path, 'pubspec.yaml'));

      String targetDir;
      if (pubspecFile.existsSync()) {
        // Development mode: <project_root>/database
        targetDir = p.join(currentDir.path, 'database');
      } else {
        // Portable / Release mode: <exe_dir>/database
        final exePath = overrideExecutablePath ?? Platform.resolvedExecutable;
        final exeDir = File(exePath).parent.path;
        targetDir = p.join(exeDir, 'database');
      }

      // Check write permissions on target directory
      bool isWritable = false;
      if (overrideSimulateReadOnly != true) {
        try {
          final dir = Directory(targetDir);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final probe = File(p.join(targetDir, '.probe_${DateTime.now().microsecondsSinceEpoch}'));
          probe.writeAsStringSync('write_test');
          isWritable = true;
          try {
            probe.deleteSync();
          } catch (_) {}
        } catch (_) {
          isWritable = false;
        }
      }

      if (isWritable) {
        return targetDir;
      }

      // Read-only fallback: AppSupport/database
      final supportDir = overrideSupportDirectory ?? await getApplicationSupportDirectory();
      final fallbackDir = Directory(p.join(supportDir.path, 'database'));
      if (!fallbackDir.existsSync()) {
        fallbackDir.createSync(recursive: true);
      }
      return fallbackDir.path;
    }

    // Mobile platforms (Android / iOS)
    final supportDir = overrideSupportDirectory ?? await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(supportDir.path, 'database'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return dbDir.path;
  }

  /// Resolves the absolute path for a SQLite database file with the given [fileName].
  ///
  /// On Web, returns [fileName] directly since virtual storage is used.
  /// On Desktop and Mobile, joins [fileName] with [resolveDatabaseDirectory].
  static Future<String> resolveDatabasePath(String fileName) async {
    if (kIsWeb) return fileName;
    final dir = await resolveDatabaseDirectory();
    return p.join(dir, fileName);
  }

  /// Migrates `user_data.sqlite` and `pokedex.sqlite` (plus WAL & SHM) from the Documents directory.
  ///
  /// Inspects the legacy Documents folder for previously stored databases, copies them
  /// safely to the new portable database directory, resolves modification timestamp
  /// conflicts with automatic backups, and removes obsolete files after verification.
  static Future<void> migrateLegacyDocumentsDatabasesIfNeeded() async {
    if (kIsWeb) return;
    if (overrideDocumentsDirectory == null &&
        (Platform.environment.containsKey('FLUTTER_TEST') ||
         Platform.environment.containsKey('DART_TEST') ||
         Platform.script.path.contains('test'))) {
      return;
    }

    final Directory docDir = overrideDocumentsDirectory ?? await getApplicationDocumentsDirectory();
    final String targetDir = await resolveDatabaseDirectory();

    // If target directory is the same as documents directory, do nothing
    if (p.canonicalize(docDir.path) == p.canonicalize(targetDir)) return;

    final targetDirectory = Directory(targetDir);
    if (!targetDirectory.existsSync()) {
      targetDirectory.createSync(recursive: true);
    }

    // 1. Migrate user_data.sqlite
    await _migrateUserDataDb(docDir, targetDirectory);

    // 2. Migrate pokedex.sqlite
    await _migratePokedexDb(docDir, targetDirectory);
  }

  static Future<void> _migrateUserDataDb(Directory docDir, Directory targetDir) async {
    final docDb = File(p.join(docDir.path, 'user_data.sqlite'));
    final targetDb = File(p.join(targetDir.path, 'user_data.sqlite'));

    if (docDb.existsSync()) {
      if (!targetDb.existsSync()) {
        await _copyVerifyDelete(docDb, targetDb);
        for (final ext in ['-wal', '-shm']) {
          final docAux = File(p.join(docDir.path, 'user_data.sqlite$ext'));
          final targetAux = File(p.join(targetDir.path, 'user_data.sqlite$ext'));
          if (docAux.existsSync()) {
            await _copyVerifyDelete(docAux, targetAux);
          }
        }
      } else {
        // Conflict resolution: compare modified timestamps
        final docModified = docDb.lastModifiedSync();
        final targetModified = targetDb.lastModifiedSync();
        if (docModified.isAfter(targetModified)) {
          // Documents file is newer: back up target database and any auxiliary files
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final backupPath = p.join(
            targetDir.path,
            'user_data.sqlite.bak_$timestamp',
          );
          await targetDb.copy(backupPath);

          for (final ext in ['-wal', '-shm']) {
            final targetAux = File(p.join(targetDir.path, 'user_data.sqlite$ext'));
            if (targetAux.existsSync()) {
              await targetAux.copy(p.join(targetDir.path, 'user_data.sqlite$ext.bak_$timestamp'));
              try {
                await targetAux.delete();
              } catch (_) {}
            }
          }

          // Copy newer Documents files to target
          await _copyVerifyDelete(docDb, targetDb);
          for (final ext in ['-wal', '-shm']) {
            final docAux = File(p.join(docDir.path, 'user_data.sqlite$ext'));
            final targetAux = File(p.join(targetDir.path, 'user_data.sqlite$ext'));
            if (docAux.existsSync()) {
              await _copyVerifyDelete(docAux, targetAux);
            }
          }
        } else {
          // Target is newer or equal: clean up legacy documents database and auxiliary files
          try {
            await docDb.delete();
          } catch (_) {}
          for (final ext in ['-wal', '-shm']) {
            final docAux = File(p.join(docDir.path, 'user_data.sqlite$ext'));
            if (docAux.existsSync()) {
              try {
                await docAux.delete();
              } catch (_) {}
            }
          }
        }
      }
    } else {
      // No main db in documents: clean up any orphaned wal/shm files in documents
      for (final ext in ['-wal', '-shm']) {
        final docAux = File(p.join(docDir.path, 'user_data.sqlite$ext'));
        if (docAux.existsSync()) {
          try {
            await docAux.delete();
          } catch (_) {}
        }
      }
    }
  }

  static Future<void> _migratePokedexDb(Directory docDir, Directory targetDir) async {
    final docDb = File(p.join(docDir.path, 'pokedex.sqlite'));
    final targetDb = File(p.join(targetDir.path, 'pokedex.sqlite'));

    if (docDb.existsSync()) {
      if (!targetDb.existsSync()) {
        await _copyVerifyDelete(docDb, targetDb);
        for (final ext in ['-wal', '-shm']) {
          final docAux = File(p.join(docDir.path, 'pokedex.sqlite$ext'));
          final targetAux = File(p.join(targetDir.path, 'pokedex.sqlite$ext'));
          if (docAux.existsSync()) {
            await _copyVerifyDelete(docAux, targetAux);
          }
        }
      } else {
        // Target already exists: clean up old documents file and auxiliary files
        try {
          await docDb.delete();
        } catch (_) {}
        for (final ext in ['-wal', '-shm']) {
          final docAux = File(p.join(docDir.path, 'pokedex.sqlite$ext'));
          if (docAux.existsSync()) {
            try {
              await docAux.delete();
            } catch (_) {}
          }
        }
      }
    } else {
      // Clean up any orphaned pokedex.sqlite-wal and pokedex.sqlite-shm in documents
      for (final ext in ['-wal', '-shm']) {
        final docAux = File(p.join(docDir.path, 'pokedex.sqlite$ext'));
        if (docAux.existsSync()) {
          try {
            await docAux.delete();
          } catch (_) {}
        }
      }
    }
  }

  static Future<void> _copyVerifyDelete(File source, File destination) async {
    final copied = await source.copy(destination.path);
    if (copied.existsSync() && copied.lengthSync() == source.lengthSync()) {
      try {
        await source.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete legacy file ${source.path} after copy: $e');
      }
    }
  }
}
