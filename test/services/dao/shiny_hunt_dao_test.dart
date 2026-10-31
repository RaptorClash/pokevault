import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/services/dao/shiny_hunt_dao.dart';
import 'package:pokevault/services/dao/database_migrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ShinyHuntDao shinyHuntDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 13,
        onCreate: DatabaseMigrator.createUserDataTables,
      ),
    );
    shinyHuntDao = ShinyHuntDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ShinyHuntDao Isolated Tests (TDD)', () {
    test('saveShinyHunt and getShinyHunt / getAllShinyHunts persists correctly', () async {
      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-1',
        title: 'Mewtwo Hunt',
        pokemonId: 150,
        pokemonName: 'Mewtwo',
        game: 'FireRed',
        generation: 3.0,
        method: 'soft_reset',
        baseOdds: 8192.0,
        currentEncounters: 450,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      await shinyHuntDao.saveShinyHunt(hunt);

      final loaded = await shinyHuntDao.getShinyHunt('hunt-1');
      expect(loaded, isNotNull);
      expect(loaded!.title, equals('Mewtwo Hunt'));
      expect(loaded.pokemonId, equals(150));
      expect(loaded.currentEncounters, equals(450));

      final all = await shinyHuntDao.getAllShinyHunts();
      expect(all.length, equals(1));
      expect(all.first.id, equals('hunt-1'));
    });

    test('deleteShinyHunt supports soft-delete and hard-delete', () async {
      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-del',
        title: 'Hunt to delete',
        pokemonId: 25,
        pokemonName: 'Pikachu',
        game: 'Emerald',
        generation: 3.0,
        method: 'wild',
        baseOdds: 8192.0,
        createdAt: now,
        updatedAt: now,
      );
      await shinyHuntDao.saveShinyHunt(hunt);

      // 1. Soft-delete
      await shinyHuntDao.deleteShinyHunt('hunt-del', softDelete: true);

      final active = await shinyHuntDao.getAllShinyHunts(includeDeleted: false);
      expect(active, isEmpty);

      final withDeleted = await shinyHuntDao.getAllShinyHunts(includeDeleted: true);
      expect(withDeleted.length, equals(1));
      expect(withDeleted.first.id, equals('hunt-del'));

      // 2. Hard-delete
      await shinyHuntDao.deleteShinyHunt('hunt-del', softDelete: false);
      final afterHardDelete = await shinyHuntDao.getAllShinyHunts(includeDeleted: true);
      expect(afterHardDelete, isEmpty);
    });
  });
}
