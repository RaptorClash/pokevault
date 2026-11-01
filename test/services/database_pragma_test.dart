import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Database PRAGMA Android Compatibility Tests', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    });

    tearDown(() async {
      await db.close();
    });

    test('All onOpen PRAGMAs execute cleanly via rawQuery without throwing', () async {
      // Must use rawQuery instead of execute to satisfy Android's SQLiteDatabase check
      await expectLater(db.rawQuery('PRAGMA busy_timeout = 30000;'), completes);
      await expectLater(db.rawQuery('PRAGMA synchronous = NORMAL;'), completes);
      await expectLater(db.rawQuery('PRAGMA temp_store = MEMORY;'), completes);
      await expectLater(db.rawQuery('PRAGMA journal_mode = WAL;'), completes);
      await expectLater(db.rawQuery('PRAGMA foreign_keys = ON;'), completes);
      await expectLater(db.rawQuery('PRAGMA optimize;'), completes);
    });

    test('Transaction PRAGMAs execute cleanly via rawQuery', () async {
      await db.transaction((txn) async {
        await expectLater(txn.rawQuery('PRAGMA defer_foreign_keys = ON;'), completes);
      });
    });

    test('PRAGMA values are successfully set via rawQuery', () async {
      await db.rawQuery('PRAGMA busy_timeout = 30000;');
      final timeoutResult = await db.rawQuery('PRAGMA busy_timeout;');
      expect(timeoutResult.first.values.first, 30000);

      await db.rawQuery('PRAGMA foreign_keys = ON;');
      final fkResult = await db.rawQuery('PRAGMA foreign_keys;');
      expect(fkResult.first.values.first, 1);
    });
  });
}
