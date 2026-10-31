import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/utils/dex_logic_helper.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DexProvider provider;
  late MockDatabaseService mockDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockDb = MockDatabaseService();

    when(() => mockDb.getAllPokemon()).thenAnswer((_) async => []);
    when(() => mockDb.getAllDexOrders()).thenAnswer((_) async => {});
    when(() => mockDb.getBallUrls()).thenAnswer((_) async => {});
    when(() => mockDb.getAllRibbons()).thenAnswer((_) async => []);
    when(() => mockDb.getAllUserDexes()).thenAnswer((_) async => []);
    when(() => mockDb.getAllFolders()).thenAnswer((_) async => []);
    when(() => mockDb.getStructure()).thenAnswer((_) async => {'root': []});
    when(
      () => mockDb.savePokemonStatus(
        any(),
        any(),
        isCaught: any(named: 'isCaught'),
        isShiny: any(named: 'isShiny'),
        isIgnored: any(named: 'isIgnored'),
        isAlpha: any(named: 'isAlpha'),
      ),
    ).thenAnswer((_) async {});

    provider = DexProvider(databaseService: mockDb);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  group('DexProvider - Unmarking Pokémon with Orphaned/Legacy Instance IDs (TDD)', () {
    test('Unchecking a Pokémon removes matching instance IDs even when customBoxes is empty', () async {
      final dex = UserDex(
        id: 'test_dex_1',
        title: 'Nationaldex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [],
        caughtIds: [
          '1_normal',
          '1',
          '1_normal__1792332742865_228296846_0',
        ],
      );

      provider.userDexes = [dex];

      // Initially, Bulbasaur is caught
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isTrue);

      // User clicks Bulbasaur in box view to uncheck it
      provider.togglePokemon('test_dex_1', '1_normal');

      // The instance ID must be purged and isPokemonCaught must now be FALSE!
      expect(dex.caughtIds.contains('1_normal__1792332742865_228296846_0'), isFalse,
          reason: 'Legacy instance ID must be removed from caughtIds when unchecking');
      expect(dex.caughtIds.contains('1_normal'), isFalse);
      expect(dex.caughtIds.contains('1'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '1_normal'), isFalse,
          reason: 'Bulbasaur must be completely uncaught after unchecking');
    });

    test('Unchecking male gender variant cleans up male instance IDs but preserves female instance IDs', () async {
      final dex = UserDex(
        id: 'test_dex_2',
        title: 'Nationaldex Genders',
        region: 'national_overall',
        includeGenders: true,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [],
        caughtIds: [
          '25_m',
          '25_m__123456_0',
          '25_f',
          '25_f__654321_1',
          '25',
        ],
      );

      provider.userDexes = [dex];

      expect(DexLogicHelper.isPokemonCaught(dex, '25_m'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_f'), isTrue);

      // Uncheck male Pikachu
      provider.togglePokemon('test_dex_2', '25_m');

      // Male must be uncaught and male instance removed
      expect(dex.caughtIds.contains('25_m'), isFalse);
      expect(dex.caughtIds.contains('25_m__123456_0'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_m'), isFalse);

      // Female must STILL be caught with its instance intact
      expect(dex.caughtIds.contains('25_f'), isTrue);
      expect(dex.caughtIds.contains('25_f__654321_1'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '25_f'), isTrue);
    });

    test('Unchecking normal form cleans up normal instances but preserves regional form instances', () async {
      final dex = UserDex(
        id: 'test_dex_3',
        title: 'Nationaldex Forms',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: true,
        includeMega: true,
        includeGMax: true,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [],
        caughtIds: [
          '19_normal',
          '19_normal__111_0',
          '19_alola',
          '19_alola__222_1',
          '19',
        ],
      );

      provider.userDexes = [dex];

      expect(DexLogicHelper.isPokemonCaught(dex, '19_normal'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '19_alola'), isTrue);

      // Uncheck normal Rattata
      provider.togglePokemon('test_dex_3', '19_normal');

      // Normal must be uncaught
      expect(dex.caughtIds.contains('19_normal'), isFalse);
      expect(dex.caughtIds.contains('19_normal__111_0'), isFalse);
      expect(DexLogicHelper.isPokemonCaught(dex, '19_normal'), isFalse);

      // Alola must STILL be caught
      expect(dex.caughtIds.contains('19_alola'), isTrue);
      expect(dex.caughtIds.contains('19_alola__222_1'), isTrue);
      expect(DexLogicHelper.isPokemonCaught(dex, '19_alola'), isTrue);
    });
  });
}
