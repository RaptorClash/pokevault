import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/dao/pokemon_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PokemonDao pokemonDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE pokemon (
              id INTEGER PRIMARY KEY,
              name_de TEXT,
              name_en TEXT,
              type1 TEXT,
              type2 TEXT,
              generation INTEGER,
              is_legendary INTEGER,
              is_mythical INTEGER
            );
          ''');
          await db.execute('''
            CREATE TABLE forms (
              id INTEGER PRIMARY KEY,
              pokemon_id INTEGER,
              name TEXT,
              form_type TEXT,
              min_gen INTEGER,
              image_id INTEGER,
              types TEXT,
              exclusive_regions TEXT,
              forced_tera_type TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE shiny_locks (
              id INTEGER PRIMARY KEY,
              pokemon_id INTEGER,
              game_version TEXT,
              reason TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE dex_orders (
              dex_name TEXT,
              pokemon_id INTEGER,
              order_index INTEGER
            );
          ''');
          await db.execute('''
            CREATE TABLE special_dexes (
              dex_name TEXT,
              pokemon_id INTEGER
            );
          ''');
          await db.execute('''
            CREATE TABLE ribbons (
              id TEXT PRIMARY KEY,
              name_de TEXT,
              name_en TEXT,
              description_de TEXT,
              description_en TEXT,
              image_path TEXT,
              group_name TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE default_levels (
              pokemon_id INTEGER PRIMARY KEY,
              default_level INTEGER
            );
          ''');
          await db.execute('''
            CREATE TABLE shiny_categories (
              pokemon_id INTEGER,
              category TEXT
            );
          ''');
        },
      ),
    );

    // Insert mock data
    await db.insert('pokemon', {
      'id': 25,
      'name_de': 'Pikachu',
      'name_en': 'Pikachu',
      'type1': 'electric',
      'type2': null,
      'generation': 1,
      'is_legendary': 0,
      'is_mythical': 0,
    });
    await db.insert('forms', {
      'id': 2501,
      'pokemon_id': 25,
      'name': 'pikachu-alola-cap',
      'form_type': 'cap',
      'min_gen': 7,
      'image_id': 25,
      'types': 'electric',
      'exclusive_regions': 'alola',
    });
    await db.insert('shiny_locks', {
      'id': 1,
      'pokemon_id': 25,
      'game_version': 'lets-go-pikachu',
      'reason': 'Starter Pikachu cannot be shiny',
    });
    await db.insert('dex_orders', {
      'dex_name': 'kanto',
      'pokemon_id': 25,
      'order_index': 25,
    });
    await db.insert('ribbons', {
      'id': 'champion_kalos',
      'name_de': 'Kalos-Champ-Band',
      'name_en': 'Kalos Champion Ribbon',
      'description_de': 'Band für Sieg über Liga',
      'description_en': 'Ribbon for League',
      'image_path': 'kalos.png',
      'group_name': 'champion',
    });
    await db.insert('default_levels', {
      'pokemon_id': 25,
      'default_level': 5,
    });
    await db.insert('shiny_categories', {
      'pokemon_id': 25,
      'category': 'gen1_wild',
    });

    pokemonDao = PokemonDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PokemonDao Isolated Tests (TDD)', () {
    test('getAllPokemon retrieves pokemon with forms', () async {
      final list = await pokemonDao.getAllPokemon();
      expect(list.length, equals(1));
      expect(list.first.id, equals(25));
      expect(list.first.nameDe, equals('Pikachu'));
      expect(list.first.forms.length, equals(1));
      expect(list.first.forms.first.name, equals('pikachu-alola-cap'));
    });

    test('getShinyLocks and getAllShinyLocks retrieve locks from DB and cache', () async {
      final allLocks = await pokemonDao.getAllShinyLocks();
      expect(allLocks.length, equals(1));
      expect(allLocks.first['pokemon_id'], equals(25));

      final pikachuLocks = await pokemonDao.getShinyLocks(25);
      expect(pikachuLocks.length, equals(1));

      final emptyLocks = await pokemonDao.getShinyLocks(999);
      expect(emptyLocks, isEmpty);
    });

    test('getAllDexOrders builds map including national_overall fallback', () async {
      final orders = await pokemonDao.getAllDexOrders();
      expect(orders.containsKey('kanto'), isTrue);
      expect(orders['kanto'], equals([25]));
      expect(orders.containsKey('national_overall'), isTrue);
    });

    test('getAllRibbons returns cached reference and clearMemoryCache invalidates it', () async {
      final r1 = await pokemonDao.getAllRibbons();
      final r2 = await pokemonDao.getAllRibbons();
      expect(identical(r1, r2), isTrue);

      pokemonDao.clearMemoryCache();
      final r3 = await pokemonDao.getAllRibbons();
      expect(identical(r1, r3), isFalse);
      expect(r3.length, equals(1));
    });

    test('getDefaultLevel and getShinyCategories cache results per pokemonId', () async {
      final lvl1 = await pokemonDao.getDefaultLevel(25);
      expect(lvl1, equals(5));

      final lvlDefault = await pokemonDao.getDefaultLevel(999);
      expect(lvlDefault, equals(15)); // default fallback

      final cats = await pokemonDao.getShinyCategories(25);
      expect(cats, equals(['gen1_wild']));
    });
  });
}
