import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/screens/pokemon_info/widgets/pokemon_shiny_hunts_card.dart';
import 'package:pokevault/screens/shiny_hunt/shiny_hunt_counter_screen.dart';
import 'package:pokevault/services/database_service.dart';

class MockWakelockPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements WakelockPlusPlatformInterface {
  bool _enabled = false;
  @override
  Future<void> toggle({required bool enable}) async {
    _enabled = enable;
  }
  @override
  Future<bool> get enabled async => _enabled;
  @override
  bool get isMock => true;
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class FakeDatabaseService extends Fake implements DatabaseService {
  final Map<String, ShinyHunt> _hunts = {};

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async =>
      _hunts.values.where((h) => includeDeleted || h.deletedAt == 0).toList();

  @override
  Future<ShinyHunt?> getShinyHunt(String id) async => _hunts[id];

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    _hunts[hunt.id] = hunt;
  }

  @override
  Future<void> deleteShinyHunt(String id, {bool softDelete = true}) async {
    _hunts.remove(id);
  }
}

class FakeDexProvider extends ChangeNotifier implements DexProvider {
  @override
  List<Pokemon> get allPokemon => [
        Pokemon(
          id: 487,
          nameDe: 'Giratina',
          nameEn: 'Giratina',
          hasGenderDifferences: false,
          genderRate: -1,
          captureRate: 3,
          evolutionChainId: 250,
          eggGroups: ['Undiscovered'],
          weight: 750.0,
          speed: 90,
          forms: [],
        ),
      ];

  @override
  List<UserDex> get userDexes => [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabaseService fakeDb;
  late ShinyHuntProvider huntProvider;
  late FakeDexProvider dexProvider;
  late Pokemon testPokemon;
  late DexDisplayEntry testEntry;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    HttpOverrides.global = _MockHttpOverrides();
    WakelockPlusPlatformInterface.instance = MockWakelockPlatform();
  });

  setUp(() async {
    Translator.currentLanguage = 'de';
    fakeDb = FakeDatabaseService();
    huntProvider = ShinyHuntProvider(
      databaseService: fakeDb,
      enableTimer: false,
    );
    await huntProvider.initialized;
    dexProvider = FakeDexProvider();

    testPokemon = Pokemon(
      id: 487,
      nameDe: 'Giratina',
      nameEn: 'Giratina',
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: 3,
      evolutionChainId: 250,
      eggGroups: ['Undiscovered'],
      weight: 750.0,
      speed: 90,
      forms: [],
    );

    testEntry = DexDisplayEntry(
      pokemon: testPokemon,
      uniqueId: '487',
      displaySuffix: '',
      imageUrl: 'https://img.test/487.png',
    );
  });

  tearDown(() {
    huntProvider.dispose();
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PokemonShinyHuntsCard(
            entry: testEntry,
            dexId: 'dex-1',
          ),
        ),
      ),
    );
  }

  testWidgets('Renders empty state when no hunts exist for Pokemon', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text(Translator.get('shiny_hunt_pokemon_card_title')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_no_hunts_for_pokemon')), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_start_new_for_pokemon')), findsOneWidget);
  });

  testWidgets('Renders existing hunts with encounter counts and navigates to counter on tap', (tester) async {
    final now = DateTime.now();
    final hunt = ShinyHunt(
      id: 'giratina-hunt-1',
      title: 'Giratina Reset',
      pokemonId: 487,
      pokemonName: 'Giratina',
      game: 'Platin',
      generation: 4.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      currentEncounters: 1337,
      createdAt: now,
      updatedAt: now,
    );
    await huntProvider.createHunt(hunt);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Giratina Reset'), findsOneWidget);
    expect(find.textContaining('Platin'), findsOneWidget);
    expect(find.textContaining('Soft Reset'), findsOneWidget);
    expect(find.text('1337'), findsOneWidget);
    expect(find.text(Translator.get('shiny_hunt_tab_active')), findsOneWidget);

    // Tap on hunt card -> navigates to counter screen
    await tester.tap(find.text('Giratina Reset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ShinyHuntCounterScreen), findsOneWidget);
  });

  testWidgets('PokemonShinyHuntsCard uses ExpansionTile and collapses/expands on tap', (tester) async {
    final now = DateTime.now();
    await huntProvider.createHunt(ShinyHunt(
      id: 'active-hunt',
      title: 'Active Hunt',
      pokemonId: 487,
      pokemonName: 'Giratina',
      game: 'Platin',
      generation: 4.0,
      method: 'Soft Reset',
      baseOdds: 8192.0,
      currentEncounters: 10,
      createdAt: now,
      updatedAt: now,
    ));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // ExpansionTile should be present
    expect(find.byType(ExpansionTile), findsOneWidget);
    // Active hunt is visible initially (expanded by default when active hunts exist)
    expect(find.text('Active Hunt'), findsOneWidget);

    // Tap header to collapse
    await tester.tap(find.text(Translator.get('shiny_hunt_pokemon_card_title')));
    await tester.pumpAndSettle();

    // After collapsing, content inside children is no longer visible on screen
    expect(find.text('Active Hunt'), findsNothing);
  });

  testWidgets('PokemonShinyHuntsCard filters hunts according to resolved regional form', (tester) async {
    final now = DateTime.now();

    // Hunt 1: General Raichu hunt (no specific formId)
    await huntProvider.createHunt(ShinyHunt(
      id: 'raichu-general',
      title: 'General Raichu Hunt',
      pokemonId: 26,
      pokemonName: 'Raichu',
      pokemonFormId: null,
      game: 'Karmesin',
      generation: 9.0,
      method: 'Wild',
      baseOdds: 4096.0,
      createdAt: now,
      updatedAt: now,
    ));

    // Hunt 2: Alola-Raichu specific hunt (formId: 10100)
    await huntProvider.createHunt(ShinyHunt(
      id: 'raichu-alola',
      title: 'Alola Raichu Hunt',
      pokemonId: 26,
      pokemonName: 'Raichu (Alola)',
      pokemonFormId: 10100,
      game: 'Sonne',
      generation: 7.0,
      method: 'SOS-Chaining',
      baseOdds: 315.0,
      createdAt: now,
      updatedAt: now,
    ));

    // Hunt 3: Kanto-Raichu specific hunt (formId: 26)
    await huntProvider.createHunt(ShinyHunt(
      id: 'raichu-kanto',
      title: 'Kanto Raichu Hunt',
      pokemonId: 26,
      pokemonName: 'Raichu',
      pokemonFormId: 26,
      game: 'Feuerrot',
      generation: 3.0,
      method: 'Wild',
      baseOdds: 8192.0,
      createdAt: now,
      updatedAt: now,
    ));

    final raichuPokemon = Pokemon(
      id: 26,
      nameDe: 'Raichu',
      nameEn: 'Raichu',
      hasGenderDifferences: false,
      genderRate: 4,
      captureRate: 75,
      evolutionChainId: 10,
      eggGroups: ['Field', 'Fairy'],
      weight: 30.0,
      speed: 110,
      forms: [],
    );

    // Entry 1: Alola Raichu
    final alolaEntry = DexDisplayEntry(
      pokemon: raichuPokemon,
      uniqueId: '26-alola',
      displaySuffix: 'Alola',
      imageUrl: 'https://img.test/26-alola.png',
      form: PokemonForm(
        name: 'alola',
        formType: 'regional',
        minGen: 7,
        imageId: 10100,
        types: ['electric', 'psychic'],
        exclusiveRegions: ['alola'],
      ),
    );

    // Entry 2: Base Kanto Raichu
    final kantoEntry = DexDisplayEntry(
      pokemon: raichuPokemon,
      uniqueId: '26',
      displaySuffix: '',
      imageUrl: 'https://img.test/26.png',
      form: null,
    );

    // Test with Alola entry
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
          ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PokemonShinyHuntsCard(entry: alolaEntry, dexId: 'dex-1'),
          ),
        ),
      ),
    );
    await tester.pump();

    // Alola entry should show Alola hunt and General hunt, but NOT Kanto-specific hunt
    expect(find.text('Alola Raichu Hunt'), findsOneWidget);
    expect(find.text('General Raichu Hunt'), findsOneWidget);
    expect(find.text('Kanto Raichu Hunt'), findsNothing);

    // Now test with Kanto base entry
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
          ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PokemonShinyHuntsCard(entry: kantoEntry, dexId: 'dex-1'),
          ),
        ),
      ),
    );
    await tester.pump();

    // Kanto entry should show General hunt and Kanto hunt, but NOT Alola-specific hunt
    expect(find.text('General Raichu Hunt'), findsOneWidget);
    expect(find.text('Kanto Raichu Hunt'), findsOneWidget);
    expect(find.text('Alola Raichu Hunt'), findsNothing);
  });
}
